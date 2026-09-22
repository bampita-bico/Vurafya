import asyncio
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from backend.config import settings
from backend.utils.database import check_db, get_db_path
from backend.services.background_worker import stability_background_worker
from backend.services.cdfd_bridge import ONTOLOGY_AVAILABLE, ontology, runtime_status


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings.validate_deployment()
    db_info = await check_db()
    app.state.db_info = db_info

    # Bootstrap the optional Neo4j graph layer when the runtime web layer exists.
    if ONTOLOGY_AVAILABLE and ontology is not None:
        try:
            ontology.ensure_schema()
            print("Neo4j ontology schema verified.")
        except Exception as e:
            print(f"Neo4j bootstrap warning: {e}")
    else:
        print(f"CDFD graph layer unavailable: {runtime_status().get('ontology_error')}")

    # The worker is opt-in: core app routes do not depend on model processing.
    if settings.ENABLE_BACKGROUND_WORKER:
        db_path = get_db_path()
        asyncio.create_task(stability_background_worker(db_path))

    yield


app = FastAPI(
    title="Vurafya API",
    description="Health platform API - Nutrition, Gamification, and medical workflows",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def health():
    db_info = await check_db()
    return {"status": "ok", "database": db_info, "cdfd_runtime": runtime_status()}


# Import and mount routers after they're created
from backend.api.auth import router as auth_router
from backend.api.users import router as users_router
from backend.api.subscriptions import router as subscriptions_router
from backend.api.nutrition import router as nutrition_router
from backend.api.game import router as game_router
from backend.api.pharmacy import router as pharmacy_router
from backend.api.biometrics import router as biometrics_router
from backend.api.medical import router as medical_router
from backend.api.game_extras import router as game_extras_router
from backend.api.trust import router as trust_router
from backend.api.admin import router as admin_router
from backend.api.preventive import router as preventive_router
from backend.api.ai_recommendations import router as ai_router
from backend.api.social import router as social_router
from backend.api.social_good import router as social_good_router
from backend.api.push_notifications import router as push_router
from backend.api.otp import router as otp_router
from backend.api.offline_sync import router as offline_router
from backend.api.engine import router as engine_router
from backend.api.ontology import router as ontology_router
from backend.api.vuralis import router as vuralis_router

app.include_router(auth_router, prefix="/api/v1/auth", tags=["Auth"])
app.include_router(users_router, prefix="/api/v1/users", tags=["Users"])
app.include_router(subscriptions_router, prefix="/api/v1/subscriptions", tags=["Subscriptions"])
app.include_router(nutrition_router, prefix="/api/v1/nutrition", tags=["Nutrition"])
app.include_router(game_router, prefix="/api/v1/game", tags=["Game"])
app.include_router(pharmacy_router, prefix="/api/v1/pharmacy", tags=["Pharmacy"])
app.include_router(biometrics_router, prefix="/api/v1/biometrics", tags=["Biometrics"])
app.include_router(medical_router, prefix="/api/v1/medical", tags=["Medical"])
app.include_router(game_extras_router, prefix="/api/v1/game", tags=["Game Extras"])
app.include_router(trust_router, prefix="/api/v1/users", tags=["Trust & KYC"])
app.include_router(admin_router, prefix="/api/v1/admin", tags=["Admin"])
app.include_router(preventive_router, prefix="/api/v1/preventive", tags=["Preventive Medicine"])
app.include_router(ai_router, prefix="/api/v1/recommendations", tags=["AI Recommendations"])
app.include_router(social_router, prefix="/api/v1/social", tags=["Social"])
app.include_router(social_good_router, prefix="/api/v1/social-good", tags=["Social Good"])
app.include_router(push_router, prefix="/api/v1/push", tags=["Push Notifications"])
app.include_router(otp_router, prefix="/api/v1/otp", tags=["OTP"])
app.include_router(offline_router, prefix="/api/v1/offline", tags=["Offline Sync"])
app.include_router(engine_router, prefix="/api/v1/engine", tags=["Universal Engine"])
app.include_router(ontology_router, prefix="/api/v1/ontology", tags=["Ontology & Graph"])
app.include_router(vuralis_router, prefix="/api/v1/vuralis", tags=["Vuralis Metaverse Bridge"])
