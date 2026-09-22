"""Vurafya clinical prediction adapter.

Primary path is **local** biomarker → operating-band scoring (the app's own
predictive layer). CDFD Runtime kernel / CDFL / doctor surfaces are optional
enrichment and must never block stability, trajectory, avatar sync, or export.
"""
from __future__ import annotations

import os
import hashlib
from datetime import datetime
from typing import Any

import numpy as np
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

# Optional: set VURAFYA_USE_RUNTIME_KERNEL=1 to prefer Runtime kernel for trajectory.
USE_RUNTIME_KERNEL = os.getenv("VURAFYA_USE_RUNTIME_KERNEL", "").strip().lower() in {
    "1",
    "true",
    "yes",
    "on",
}

if not ENGINE_AVAILABLE:
    print(
        f"Info: CDFD Runtime optional surfaces unavailable ({KERNEL_ERROR}). "
        "Vurafya local prediction remains active."
    )


def _band(psi: float) -> str:
    if psi > 1.2:
        return "overload"
    if psi < 0.8:
        return "constrained"
    return "stable"


def _guidance(psi: float, domain: str = "vurafya_local") -> dict[str, Any]:
    """Prefer Runtime classifier when present; always fall back locally."""
    try:
        return classify_operating_state(
            psi,
            meta={"life_number": psi},
            domain=domain,
        )
    except Exception:
        if psi > 1.5:
            state = "critical_overload"
        elif psi > 1.2:
            state = "overloaded"
        elif psi >= 0.8:
            state = "balanced"
        elif psi >= 0.5:
            state = "constrained"
        else:
            state = "critical_constraint"
        return {
            "psi": psi,
            "state": state,
            "actions": ["continue_monitoring"],
            "reason": f"Psi={psi:.3f} (local band)",
            "domain": domain,
            "life_number": psi,
        }


def _unknown_guidance(domain: str = "vurafya_local") -> dict[str, Any]:
    return {
        "psi": None,
        "state": "insufficient_data",
        "actions": ["record_biometrics"],
        "reason": "No usable current biomarker measurements are available for an operating-band summary.",
        "domain": domain,
        "life_number": None,
    }


def _local_trajectory(mean_psi: float, regime: str, steps: int) -> list[dict[str, Any]]:
    """Simple mean-reverting forecast — same idea as the Flutter offline edge engine."""
    seed_material = f"{mean_psi:.4f}:{regime}:{steps}".encode()
    seed = int.from_bytes(hashlib.blake2s(seed_material, digest_size=4).digest(), "big")
    rng = np.random.default_rng(seed)
    psi = float(mean_psi)
    history: list[dict[str, Any]] = []
    for i in range(steps):
        drift = float(rng.uniform(-0.025, 0.025))
        if regime == "overload":
            drift += 0.008
        elif regime == "constrained":
            drift -= 0.008
        # Soft pull toward 1.0
        drift += 0.02 * (1.0 - psi)
        psi = float(np.clip(psi + drift, 0.1, 3.0))
        history.append(
            {
                "t": i,
                "psi": psi,
                "psi_s": psi,
                "renal_psi": psi * 0.95,
                "cardio_psi": psi * 1.05,
                "metabolic_psi": psi,
                "regime": _band(psi),
                "source": "vurafya_local",
            }
        )
    return history


class VurafyaAdapter:
    """Maps Vurafya records to local predictive scores; Runtime is optional."""

    def __init__(self, db_session=None):
        self.db_session = db_session
        self.kernel = None
        if USE_RUNTIME_KERNEL and ENGINE_AVAILABLE and Kernel is not None:
            try:
                self.kernel = Kernel()
            except Exception as exc:
                print(f"Info: Runtime kernel init skipped: {exc}")
                self.kernel = None

    async def _get_historical_baseline(self, session, table, user_id, column, days=30):
        query = text(
            f"""
            SELECT AVG({column}) as baseline
            FROM {table}
            WHERE user_id = :user_id
              AND created_at >= NOW() - INTERVAL '{days} days'
        """
        )
        if table == "creatinine_egfr_logs":
            query = text(
                f"SELECT AVG({column}) FROM {table} WHERE user_id = :user_id "
                f"AND measured_at >= NOW() - INTERVAL '{days} days'"
            )
        elif table in {"glucose_monitoring", "vital_signs_history"}:
            query = text(
                f"SELECT AVG({column}) FROM {table} WHERE user_id = :user_id "
                f"AND recorded_at >= NOW() - INTERVAL '{days} days'"
            )

        res = await session.execute(query, {"user_id": user_id})
        val = res.scalar()
        return float(val) if val is not None else None

    async def get_patient_state(self, user_id: int) -> dict:
        """
        Local predictive state from biometrics/labs.
        Does **not** require CDFD Runtime.
        """
        vitals = glucose = ckd = None
        try:
            async with AsyncSessionLocal() as session:
                res = await session.execute(
                    text(
                        "SELECT * FROM vital_signs_history WHERE user_id = :user_id "
                        "ORDER BY recorded_at DESC LIMIT 1"
                    ),
                    {"user_id": user_id},
                )
                vitals = res.mappings().first()

                res = await session.execute(
                    text(
                        "SELECT * FROM glucose_monitoring WHERE user_id = :user_id "
                        "ORDER BY recorded_at DESC LIMIT 1"
                    ),
                    {"user_id": user_id},
                )
                glucose = res.mappings().first()

                res = await session.execute(
                    text(
                        "SELECT * FROM creatinine_egfr_logs WHERE user_id = :user_id "
                        "ORDER BY measured_at DESC LIMIT 1"
                    ),
                    {"user_id": user_id},
                )
                ckd = res.mappings().first()

        except Exception as exc:
            print(f"Warning: biomarker load skipped for user {user_id}: {exc}")

        state: dict[str, Any] = {
            "prediction_engine": "vurafya_local",
            "runtime_optional": True,
            "runtime_kernel_attached": self.kernel is not None,
            "renal_psi": None,
            "cardio_psi": None,
            "metabolic_psi": None,
            "immune_psi": None,
            "ms_factors": {"renal": 1.0, "cardio": 1.0, "metabolic": 1.0},
            "regimes": {},
            "runtime_guidance_by_system": {},
            "raw": {
                "egfr": None,
                "creatinine": None,
                "pulse": None,
                "sbp": None,
                "glucose": None,
            },
        }

        if ckd and ckd.get("egfr_ml_min") is not None and ckd.get("creatinine_mg_dl") is not None:
            egfr = float(ckd["egfr_ml_min"])
            creat = float(ckd["creatinine_mg_dl"])
            if creat <= 0:
                egfr = creat = None
        else:
            egfr = creat = None
        if egfr is not None and creat is not None:
            state["raw"]["egfr"] = egfr
            state["raw"]["creatinine"] = creat
            phi_renal = egfr / 100.0
            c_renal = max(creat / 1.0, 1e-6)
            state["renal_psi"] = phi_renal / c_renal
            state["regimes"]["renal"] = _band(state["renal_psi"])
            state["runtime_guidance_by_system"]["renal"] = _guidance(
                state["renal_psi"], domain="vurafya_renal"
            )

        if vitals and vitals.get("pulse_bpm") is not None and vitals.get("blood_pressure_systolic") is not None:
            pulse = float(vitals["pulse_bpm"])
            sbp = float(vitals["blood_pressure_systolic"])
            if pulse <= 0 or sbp <= 0:
                pulse = sbp = None
        else:
            pulse = sbp = None
        if pulse is not None and sbp is not None:
            state["raw"]["pulse"] = pulse
            state["raw"]["sbp"] = sbp
            phi_cardio = 1.0 / (pulse / 70.0) if pulse > 40 else 0.5
            c_cardio = sbp / 120.0
            state["cardio_psi"] = phi_cardio / c_cardio
            state["regimes"]["cardio"] = _band(state["cardio_psi"])
            state["runtime_guidance_by_system"]["cardio"] = _guidance(
                state["cardio_psi"], domain="vurafya_cardio"
            )

        if glucose and glucose.get("glucose_mg_dl") is not None:
            glu_val = float(glucose["glucose_mg_dl"])
            if glu_val <= 0:
                glu_val = None
        else:
            glu_val = None
        if glu_val is not None:
            state["raw"]["glucose"] = glu_val
            phi_metabolic = glu_val / 100.0
            c_metabolic = max(glu_val / 100.0, 0.8)
            state["metabolic_psi"] = phi_metabolic / c_metabolic
            state["regimes"]["metabolic"] = _band(state["metabolic_psi"])
            state["runtime_guidance_by_system"]["metabolic"] = _guidance(
                state["metabolic_psi"], domain="vurafya_metabolic"
            )

        scores = {
            name: state[f"{name}_psi"]
            for name in ("renal", "cardio", "metabolic")
            if state[f"{name}_psi"] is not None
        }
        state["available_domains"] = sorted(scores)
        state["missing_domains"] = sorted({"renal", "cardio", "metabolic"} - set(scores))
        state["data_completeness"] = len(scores) / 3.0
        state["status"] = "ok" if len(scores) == 3 else ("partial" if scores else "insufficient_data")
        state["mean_psi"] = float(np.mean(list(scores.values()))) if scores else None
        state["overall_regime"] = _band(state["mean_psi"]) if scores else "insufficient_data"
        state["runtime_guidance"] = (
            _guidance(state["mean_psi"], domain="vurafya_local")
            if scores
            else _unknown_guidance()
        )
        state["t"] = datetime.now().isoformat()
        state["claim_boundary"] = (
            "Vurafya local operating-band scores are app modeling aids for review, "
            "not diagnosis or treatment. CDFD Runtime is optional and not required."
        )
        return state

    async def predict_trajectory(self, user_id: int, steps: int = 100) -> list:
        clinical_state = await self.get_patient_state(user_id)
        if clinical_state.get("mean_psi") is None:
            raise ValueError("Trajectory requires at least one usable current biomarker measurement")
        mean_psi = float(clinical_state["mean_psi"])
        regime = str(clinical_state.get("overall_regime", "stable"))

        if self.kernel is not None and State is not None and USE_RUNTIME_KERNEL:
            try:
                state = State(nx=1, ny=1)
                state.phi[0, 0] = mean_psi
                state.C[0, 0] = 1.0
                state.S[0, 0] = 1.0
                if regime == "overload":
                    state.alpha[0, 0] = 0.2
                elif regime == "constrained":
                    state.beta[0, 0] = 0.02
                history = self.kernel.run(state, steps=steps)
                for row in history:
                    if isinstance(row, dict):
                        row["source"] = "cdfd_runtime_kernel"
                return history
            except Exception as exc:
                print(f"Info: Runtime kernel trajectory failed, using local: {exc}")

        return _local_trajectory(mean_psi, regime, steps)

    async def execute_dsl(self, user_id: int, script: str) -> list:
        if not DSL_AVAILABLE:
            return [
                {
                    "error": "CDFL optional surface unavailable",
                    "hint": "Install/attach CDFD Runtime DSL to use execute-dsl",
                }
            ]

        clinical_state = await self.get_patient_state(user_id)
        if clinical_state.get("mean_psi") is None:
            return [{"error": "CDFL execution requires usable current biomarker data"}]
        raw = clinical_state["raw"]
        patient_data = {"psi": clinical_state.get("mean_psi")}
        if raw.get("egfr") is not None:
            patient_data["filtration_flux"] = raw["egfr"] / 100.0
        if raw.get("creatinine") is not None:
            patient_data["renal_constraint"] = raw["creatinine"]
        for source, target in (("glucose", "glucose_mg_dl"), ("sbp", "sbp"), ("pulse", "pulse")):
            if raw.get(source) is not None:
                patient_data[target] = raw[source]
        patient_context = {"name": "Patient", "data": patient_data}

        try:
            tokens = tokenize(script)
            nodes = parse(tokens)
            executor = Executor(nx=1, ny=1)
            executor.context["Patient"] = patient_context["data"]
            return executor.execute(nodes)
        except Exception as e:
            return [{"error": f"DSL Execution failed: {str(e)}"}]

    async def sync_avatar_stats(self, user_id: int):
        state = await self.get_patient_state(user_id)

        if state.get("mean_psi") is None:
            return {"user_id": user_id, "synced": False, "reason": "insufficient_data"}
        health_level = float(state["mean_psi"]) * 100.0
        energy_level = float(state.get("metabolic_psi") or 0.0) * 100.0
        immunity_level = float(state.get("immune_psi") or 0.0) * 100.0
        deviation = np.std(
            [
                state.get("renal_psi") or 0.0,
                state.get("cardio_psi") or 0.0,
                state.get("metabolic_psi") or 0.0,
            ]
        )
        resilience_level = (1.0 / (float(deviation) + 0.1)) * 50.0

        health_level = max(0, min(100, health_level))
        energy_level = max(0, min(100, energy_level))
        immunity_level = max(0, min(100, immunity_level))
        resilience_level = max(0, min(100, resilience_level))
        now = datetime.now()

        async with AsyncSessionLocal() as session:
            await session.execute(
                text(
                    """UPDATE avatar_stats
                   SET health_level = :hl, energy_level = :el, immunity_level = :il,
                       resilience_level = :rl, updated_at = :ua
                   WHERE user_id = :uid"""
                ),
                {
                    "hl": health_level,
                    "el": energy_level,
                    "il": immunity_level,
                    "rl": resilience_level,
                    "ua": now,
                    "uid": user_id,
                },
            )
            await session.commit()

        return {
            "user_id": user_id,
            "synced": True,
            "health": health_level,
            "energy": energy_level,
            "prediction_engine": "vurafya_local",
        }

    async def _calculate_coupling_strength(self, session, user_id, table1, col1, table2, col2, days=30):
        return 0.8

    async def sync_ontology(self, user_id: int):
        if not ONTOLOGY_AVAILABLE or ontology is None:
            return {
                "error": "Ontology optional surface unavailable",
                "prediction_engine": "vurafya_local",
            }

        state = await self.get_patient_state(user_id)
        p_id = f"patient_{user_id}"
        ontology.upsert_patient(p_id, {"v_id": user_id})

        async with AsyncSessionLocal() as session:
            metabolic_renal_strength = await self._calculate_coupling_strength(
                session,
                user_id,
                "glucose_monitoring",
                "glucose_mg_dl",
                "creatinine_egfr_logs",
                "egfr_ml_min",
            )
            cardio_renal_strength = await self._calculate_coupling_strength(
                session,
                user_id,
                "vital_signs_history",
                "blood_pressure_systolic",
                "creatinine_egfr_logs",
                "egfr_ml_min",
            )

        systems = [
            ("renal", "Renal System", state.get("renal_psi")),
            ("cardio", "Cardiovascular System", state.get("cardio_psi")),
            ("metabolic", "Metabolic System", state.get("metabolic_psi")),
            ("immune", "Immune System", state.get("immune_psi")),
        ]

        for sid_short, s_type, psi in systems:
            if psi is None:
                continue
            sid = f"{p_id}:{sid_short}"
            ontology.upsert_system(sid, s_type, patient_id=p_id, field_id="medicine")
            cls = "stable" if 0.8 <= psi <= 1.2 else ("overload" if psi > 1.2 else "constrained")
            ontology.record_state(
                sid,
                psi,
                cls,
                meta={
                    "regime": state.get("regimes", {}).get(sid_short, ""),
                    "ms_factor": state.get("ms_factors", {}).get(sid_short, 1.0),
                },
            )

        ontology.link_system_interaction(
            f"{p_id}:metabolic", f"{p_id}:renal", strength=metabolic_renal_strength
        )
        ontology.link_system_interaction(
            f"{p_id}:cardio", f"{p_id}:renal", strength=cardio_renal_strength
        )
        ontology.link_system_interaction(f"{p_id}:metabolic", f"{p_id}:cardio", strength=0.7)

        return {"patient_id": p_id, "nodes_synced": len(systems), "coupling_updated": True}
