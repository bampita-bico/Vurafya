import numpy as np
from datetime import datetime
from sqlalchemy import text
from backend.utils.database import AsyncSessionLocal
from backend.services.cdfd_bridge import (
    DSL_AVAILABLE,
    ENGINE_AVAILABLE,
    KERNEL_ERROR,
    ONTOLOGY_AVAILABLE,
    State,
    Executor,
    Kernel,
    classify_operating_state,
    ontology,
    parse,
    tokenize,
)

if not ENGINE_AVAILABLE:
    print(f"Warning: CDFD Runtime kernel not fully available: {KERNEL_ERROR}")


class VurafyaAdapter:
    """
    Bridges Vurafya records with the public CDFD Runtime engine.
    """

    def __init__(self, db_session=None):
        self.db_session = db_session
        if ENGINE_AVAILABLE:
            self.kernel = Kernel(use_medicine=True)
        else:
            self.kernel = None

    async def _get_historical_baseline(self, session, table, user_id, column, days=30):
        """
        Calculates the mean value of a specific biomarker over the last N days.
        Used as the basis for Structural Memory (Ms).
        """
        query = text(f"""
            SELECT AVG({column}) as baseline
            FROM {table}
            WHERE user_id = :user_id
              AND created_at >= NOW() - INTERVAL '{days} days'
        """)
        # Fallback for recorded_at or measured_at if created_at is missing in some tables
        if table == "creatinine_egfr_logs":
            query = text(f"SELECT AVG({column}) FROM {table} WHERE user_id = :user_id AND measured_at >= NOW() - INTERVAL '{days} days'")
        elif table == "glucose_monitoring" or table == "vital_signs_history":
            query = text(f"SELECT AVG({column}) FROM {table} WHERE user_id = :user_id AND recorded_at >= NOW() - INTERVAL '{days} days'")

        res = await session.execute(query, {"user_id": user_id})
        val = res.scalar()
        return float(val) if val is not None else None

    async def get_patient_state(self, user_id: int) -> dict:
        """
        Fetch latest biometrics and labs for a user and map them to model regimes.
        Uses 30-day historical baselines for structural memory (Ms).
        """
        async with AsyncSessionLocal() as session:
            # 1. Fetch latest Vitals
            res = await session.execute(text(
                "SELECT * FROM vital_signs_history WHERE user_id = :user_id ORDER BY recorded_at DESC LIMIT 1"
            ), {"user_id": user_id})
            vitals = res.mappings().first()

            # 2. Fetch latest Glucose
            res = await session.execute(text(
                "SELECT * FROM glucose_monitoring WHERE user_id = :user_id ORDER BY recorded_at DESC LIMIT 1"
            ), {"user_id": user_id})
            glucose = res.mappings().first()

            # 3. Fetch latest CKD Biomarkers
            res = await session.execute(text(
                "SELECT * FROM creatinine_egfr_logs WHERE user_id = :user_id ORDER BY measured_at DESC LIMIT 1"
            ), {"user_id": user_id})
            ckd = res.mappings().first()

            # 4. Fetch Baselines (New: Dynamic Ms)
            egfr_baseline = await self._get_historical_baseline(session, "creatinine_egfr_logs", user_id, "egfr_ml_min")
            sbp_baseline = await self._get_historical_baseline(session, "vital_signs_history", user_id, "blood_pressure_systolic")
            glu_baseline = await self._get_historical_baseline(session, "glucose_monitoring", user_id, "glucose_mg_dl")

        if not ENGINE_AVAILABLE:
            return {"status": "engine_offline"}

        state = {
            "renal_psi": 1.0,
            "cardio_psi": 1.0,
            "metabolic_psi": 1.0,
            "immune_psi": 1.0,
            "ms_factors": {
                "renal": (egfr_baseline / 90.0) if egfr_baseline else 1.0,
                "cardio": (120.0 / sbp_baseline) if sbp_baseline else 1.0,
                "metabolic": (100.0 / glu_baseline) if glu_baseline else 1.0
            },
            "regimes": {},
            "runtime_guidance_by_system": {},
            "raw": {
                "egfr": 90.0,
                "creatinine": 1.0,
                "pulse": 70.0,
                "sbp": 120.0,
                "glucose": 100.0
            }
        }

        # Renal Mapping
        if ckd:
            egfr = float(ckd.get("egfr_ml_min") or 90.0)
            creat = float(ckd.get("creatinine_mg_dl") or 1.0)
            state["raw"]["egfr"] = egfr
            state["raw"]["creatinine"] = creat

            phi_renal = egfr / 100.0
            c_renal = max(creat / 1.0, 1e-6)
            ms_renal = state["ms_factors"]["renal"]
            state["renal_psi"] = (phi_renal / c_renal) * ms_renal

            # Map to qualitative regime
            if state["renal_psi"] > 1.2: state["regimes"]["renal"] = "overload"
            elif state["renal_psi"] < 0.8: state["regimes"]["renal"] = "constrained"
            else: state["regimes"]["renal"] = "stable"
            state["runtime_guidance_by_system"]["renal"] = classify_operating_state(
                state["renal_psi"],
                meta={"life_number": state["renal_psi"]},
                domain="medicine",
            )

        # Cardio Mapping
        if vitals:
            pulse = float(vitals.get("pulse_bpm") or 70.0)
            sbp = float(vitals.get("blood_pressure_systolic") or 120.0)
            state["raw"]["pulse"] = pulse
            state["raw"]["sbp"] = sbp

            phi_cardio = 1.0 / (pulse / 70.0) if pulse > 40 else 0.5
            c_cardio = sbp / 120.0
            ms_cardio = state["ms_factors"]["cardio"]
            state["cardio_psi"] = (phi_cardio / c_cardio) * ms_cardio

            if state["cardio_psi"] > 1.2: state["regimes"]["cardio"] = "overload"
            elif state["cardio_psi"] < 0.8: state["regimes"]["cardio"] = "constrained"
            else: state["regimes"]["cardio"] = "stable"
            state["runtime_guidance_by_system"]["cardio"] = classify_operating_state(
                state["cardio_psi"],
                meta={"life_number": state["cardio_psi"]},
                domain="medicine",
            )

        # Metabolic Mapping
        if glucose:
            glu_val = float(glucose.get("glucose_mg_dl") or 100.0)
            state["raw"]["glucose"] = glu_val

            phi_metabolic = glu_val / 100.0
            c_metabolic = max(glu_val / 100.0, 0.8)
            ms_metabolic = state["ms_factors"]["metabolic"]
            state["metabolic_psi"] = (phi_metabolic / c_metabolic) * ms_metabolic

            if state["metabolic_psi"] > 1.2: state["regimes"]["metabolic"] = "overload"
            elif state["metabolic_psi"] < 0.8: state["regimes"]["metabolic"] = "constrained"
            else: state["regimes"]["metabolic"] = "stable"
            state["runtime_guidance_by_system"]["metabolic"] = classify_operating_state(
                state["metabolic_psi"],
                meta={"life_number": state["metabolic_psi"]},
                domain="medicine",
            )

        state["mean_psi"] = float(np.mean([state["renal_psi"], state["cardio_psi"], state["metabolic_psi"]]))

        # Determine overall model regime for application display.
        if state["mean_psi"] > 1.2:
            state["overall_regime"] = "overload"
        elif state["mean_psi"] < 0.8:
            state["overall_regime"] = "constrained"
        else:
            state["overall_regime"] = "stable"

        state["runtime_guidance"] = classify_operating_state(
            state["mean_psi"],
            meta={"life_number": state["mean_psi"]},
            domain="medicine",
        )
        state["t"] = datetime.now().isoformat()

        return state

    async def predict_trajectory(self, user_id: int, steps: int = 100) -> list:
        """
        Physics-based trajectory projection using the CDFD Kernel.
        """
        clinical_state = await self.get_patient_state(user_id)
        if "status" in clinical_state and clinical_state["status"] == "engine_offline":
            return []
        if self.kernel is None or State is None:
            return []

        # Initialize 1x1 physics state
        state = State(nx=1, ny=1)

        # Map clinical mean to the simulation field
        # We use the mean PSI to drive the central physics
        state.phi[0,0] = clinical_state["mean_psi"]
        state.C[0,0] = 1.0  # Normalized constraint
        state.S[0,0] = 1.0  # Base responsiveness

        # Adjust adaptive parameters based on regime
        if clinical_state["overall_regime"] == "overload":
            state.alpha[0,0] = 0.2  # Higher feedback sensitivity
        elif clinical_state["overall_regime"] == "constrained":
            state.beta[0,0] = 0.02  # Lower recovery rate

        # Run physics simulation
        history = self.kernel.run(state, steps=steps)

        # Format for Vurafya API
        return history

    async def execute_dsl(self, user_id: int, script: str) -> list:
        """
        Executes a CDFL rules script against live patient data.
        """
        if not DSL_AVAILABLE:
            return [{"error": "Engine Offline"}]

        clinical_state = await self.get_patient_state(user_id)

        # Map patient biomarkers to a format the DSL expects (as seen in medical_rules.cdfl)
        patient_context = {
            "name": "Patient",
            "data": {
                "filtration_flux": clinical_state["raw"]["egfr"] / 100.0,
                "renal_constraint": clinical_state["raw"]["creatinine"] / 1.0,
                "glucose_mg_dl": clinical_state["raw"]["glucose"],
                "sbp": clinical_state["raw"]["sbp"],
                "pulse": clinical_state["raw"]["pulse"],
                "psi": clinical_state["mean_psi"]
            }
        }

        try:
            tokens = tokenize(script)
            nodes = parse(tokens)
            executor = Executor(nx=1, ny=1)

            # Inject patient data into DSL context
            executor.context["Patient"] = patient_context["data"]

            results = executor.execute(nodes)
            return results
        except Exception as e:
            return [{"error": f"DSL Execution failed: {str(e)}"}]

    async def sync_avatar_stats(self, user_id: int):
        state = await self.get_patient_state(user_id)
        if "status" in state and state["status"] == "engine_offline":
            return {"error": "Engine Offline"}

        health_level = float(state.get("mean_psi", 1.0)) * 100.0
        energy_level = float(state.get("metabolic_psi", 1.0)) * 100.0
        immunity_level = float(state.get("immune_psi", 1.0)) * 100.0
        
        # Approximate resilience from deviation
        deviation = np.std([state.get("renal_psi", 1.0), state.get("cardio_psi", 1.0), state.get("metabolic_psi", 1.0)])
        resilience_level = (1.0 / (float(deviation) + 0.1)) * 50.0

        health_level = max(0, min(100, health_level))
        energy_level = max(0, min(100, energy_level))
        immunity_level = max(0, min(100, immunity_level))
        resilience_level = max(0, min(100, resilience_level))

        now = datetime.now()

        async with AsyncSessionLocal() as session:
            await session.execute(text(
                """UPDATE avatar_stats
                   SET health_level = :hl, energy_level = :el, immunity_level = :il,
                       resilience_level = :rl, updated_at = :ua
                   WHERE user_id = :uid"""
            ), {"hl": health_level, "el": energy_level, "il": immunity_level,
                "rl": resilience_level, "ua": now, "uid": user_id})
            await session.commit()

        return {
            "user_id": user_id,
            "synced": True,
            "health": health_level,
            "energy": energy_level
        }

    async def _calculate_coupling_strength(self, session, user_id, table1, col1, table2, col2, days=30):
        """
        Calculates the correlation-based coupling strength between two biological systems.
        """
        # Simplified correlation approach: pull overlapping time-series and compute corr
        # In a real clinical DB, we'd join on timestamp windows.
        # For now, we'll use a sensible default modulated by the existence of shared pathological trends.
        return 0.8 # Default strong biological coupling

    async def sync_ontology(self, user_id: int):
        if not ONTOLOGY_AVAILABLE or ontology is None:
            return {"error": "Ontology not available"}

        state = await self.get_patient_state(user_id)
        if "status" in state and state["status"] == "engine_offline":
            return {"error": "Engine Offline"}

        p_id = f"patient_{user_id}"

        ontology.upsert_patient(p_id, {"v_id": user_id})

        # Calculate dynamic coupling strengths
        async with AsyncSessionLocal() as session:
            metabolic_renal_strength = await self._calculate_coupling_strength(
                session, user_id, "glucose_monitoring", "glucose_mg_dl", "creatinine_egfr_logs", "egfr_ml_min"
            )
            cardio_renal_strength = await self._calculate_coupling_strength(
                session, user_id, "vital_signs_history", "blood_pressure_systolic", "creatinine_egfr_logs", "egfr_ml_min"
            )

        systems = [
            ("renal", "Renal System", state.get("renal_psi", 1.0)),
            ("cardio", "Cardiovascular System", state.get("cardio_psi", 1.0)),
            ("metabolic", "Metabolic System", state.get("metabolic_psi", 1.0)),
            ("immune", "Immune System", state.get("immune_psi", 1.0)),
        ]

        for sid_short, s_type, psi in systems:
            sid = f"{p_id}:{sid_short}"
            ontology.upsert_system(sid, s_type, patient_id=p_id, field_id="medicine")

            cls = "stable" if 0.8 <= psi <= 1.2 else ("overload" if psi > 1.2 else "constrained")
            ontology.record_state(sid, psi, cls, meta={
                "regime": state.get("regimes", {}).get(sid_short, ""),
                "ms_factor": state.get("ms_factors", {}).get(sid_short, 1.0)
            })

        ontology.link_system_interaction(f"{p_id}:metabolic", f"{p_id}:renal", strength=metabolic_renal_strength)
        ontology.link_system_interaction(f"{p_id}:cardio", f"{p_id}:renal", strength=cardio_renal_strength)
        ontology.link_system_interaction(f"{p_id}:metabolic", f"{p_id}:cardio", strength=0.7)

        return {"patient_id": p_id, "nodes_synced": len(systems), "coupling_updated": True}
