import asyncio
from sqlalchemy import text
from backend.services.ai_service import generate_recommendations
from backend.services.engine_adapter import VurafyaAdapter
from backend.services.runtime_artifacts import build_patient_envelope, persist_runtime_result
from backend.utils.database import AsyncSessionLocal, DatabaseCompatSession
from backend.services.cdfd_bridge import ACTION_GATEWAY_AVAILABLE, ActionGateway


async def process_economy_integration(user_id: int, state: dict, session):
    """
    Track B: Labor & Barter Economy Integration.
    Links model state to app-level benefit and service workflows.
    """
    regime = state.get("overall_regime")
    psi = state.get("mean_psi", 1.0)
    
    if regime == "stable":
        print(f"[ECONOMY] User {user_id} is stable (Psi: {psi:.2f}). Minting 5 Afya Points (AP).")
        await session.execute(text(
            """INSERT INTO afya_points_ledger (user_id, points, reason, created_at)
               VALUES (:uid, :pts, :reason, NOW())
               ON CONFLICT DO NOTHING"""
        ), {"uid": user_id, "pts": 5, "reason": "Stable Clinical Regime"})
        
    elif regime == "constrained":
        print(f"[ECONOMY] User {user_id} is constrained (Psi: {psi:.2f}). Opening barter/labor service options.")
        await session.execute(text(
            """INSERT INTO barter_exchange_transactions (user_id, status, description, created_at)
               VALUES (:uid, 'PENDING_OFFER', :desc, NOW())
               ON CONFLICT DO NOTHING"""
        ), {"uid": user_id, "desc": "Telehealth service option via labor hours/barter"})

async def trigger_review_action(user_id: int, state: dict):
    if not ACTION_GATEWAY_AVAILABLE or ActionGateway is None:
        return
    gateway = ActionGateway()
    regime = state.get("overall_regime")
    psi = state.get("mean_psi", 1.0)
    
    if regime == "overload" and psi > 1.5:
        print(f"[ACTION GATEWAY] Marking user {user_id} for overload review (Psi: {psi:.2f})")
        gateway.execute_action("mark_for_review", f"patient_{user_id}_overload", psi)
    elif regime == "constrained" and psi < 0.6:
        print(f"[ACTION GATEWAY] Marking user {user_id} for constraint review (Psi: {psi:.2f})")
        gateway.execute_action("mark_for_review", f"patient_{user_id}_constraint", psi)


async def stability_background_worker(db_path: str = None):
    print("Vurafya Engine Background Worker started.")
    adapter = VurafyaAdapter()

    while True:
        try:
            async with AsyncSessionLocal() as session:
                compat_db = DatabaseCompatSession(session)
                res = await session.execute(text("SELECT id FROM users WHERE is_active = TRUE"))
                users = res.mappings().all()

                print(f"Background Worker: Processing {len(users)} users...")
                for user in users:
                    user_id = user["id"]
                    state = await adapter.get_patient_state(user_id)
                    
                    if state.get("status") != "engine_offline":
                        envelope = build_patient_envelope(
                            user_id=user_id,
                            kind="vurafya_background_stability",
                            command="vurafya background stability",
                            payload={"clinical_state": state},
                        )
                        await persist_runtime_result(
                            user_id=user_id,
                            result=envelope,
                            label="background-stability",
                            source="background_worker",
                            clinical_state=state,
                        )
                        await trigger_review_action(user_id, state)
                        # Track B Integration
                        await process_economy_integration(user_id, state, session)
                    
                    await generate_recommendations(compat_db, user_id)
                    await adapter.sync_avatar_stats(user_id)
                    await adapter.sync_ontology(user_id)
                    
                    await session.commit()
                    await asyncio.sleep(0.1)

            print("Background Worker: Cycle complete. Sleeping for 1 hour.")
        except Exception as e:
            print(f"Background Worker Error: {e}")

        await asyncio.sleep(3600)
