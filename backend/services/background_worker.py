import asyncio
from sqlalchemy import text
from backend.services.ai_service import generate_recommendations
from backend.services.engine_adapter import VurafyaAdapter
from backend.services.runtime_artifacts import build_patient_envelope, persist_runtime_result
from backend.utils.database import AsyncSessionLocal, DatabaseCompatSession
from backend.services.cdfd_bridge import ACTION_GATEWAY_AVAILABLE, ActionGateway
from backend.config import settings


async def trigger_review_action(user_id: int, state: dict):
    if not settings.ENABLE_MODEL_AUTOMATIONS or state.get("status") != "ok":
        return
    if not ACTION_GATEWAY_AVAILABLE or ActionGateway is None:
        return
    gateway = ActionGateway()
    regime = state.get("overall_regime")
    psi = state.get("mean_psi")
    
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
                    envelope = build_patient_envelope(
                        user_id=user_id,
                        kind="vurafya_background_stability",
                        command="vurafya local background stability",
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
                    await generate_recommendations(compat_db, user_id)
                    await adapter.sync_avatar_stats(user_id)
                    await adapter.sync_ontology(user_id)

                    await session.commit()
                    await asyncio.sleep(0.1)

            print("Background Worker: Cycle complete. Sleeping for 1 hour.")
        except Exception as e:
            print(f"Background Worker Error: {e}")

        await asyncio.sleep(3600)
