from fastapi import APIRouter, Depends, Query
from backend.utils.database import get_db
from backend.utils.dependencies import get_current_user
from backend.services.biometrics_service import (
    log_glucose, get_glucose_history,
    log_vitals, get_vitals_history, get_bp_trends,
    log_creatinine, log_potassium, log_phosphorus,
    get_ckd_dashboard,
)
from backend.models.schemas import (
    GlucoseLogCreate, VitalsLogCreate,
    CreatinineLogCreate, PotassiumLogCreate, PhosphorusLogCreate,
)

router = APIRouter()


# ── Glucose ─────────────────────────────────────────────────────────────────

@router.post("/glucose")
async def add_glucose(
    req: GlucoseLogCreate,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return await log_glucose(db, current_user["id"], req.model_dump())


@router.get("/glucose")
async def glucose_history(
    days: int = Query(7, ge=1, le=90),
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return await get_glucose_history(db, current_user["id"], days)


# ── Vital signs ─────────────────────────────────────────────────────────────

@router.post("/vitals")
async def add_vitals(
    req: VitalsLogCreate,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return await log_vitals(db, current_user["id"], req.model_dump())


@router.get("/vitals")
async def vitals_history(
    days: int = Query(30, ge=1, le=365),
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return {"vitals": await get_vitals_history(db, current_user["id"], days)}


@router.get("/bp-trends")
async def bp_trends(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    return {"trends": await get_bp_trends(db, current_user["id"])}


# ── CKD labs ─────────────────────────────────────────────────────────────────

@router.post("/ckd/creatinine")
async def add_creatinine(
    req: CreatinineLogCreate,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return await log_creatinine(db, current_user["id"], req.model_dump())


@router.post("/ckd/potassium")
async def add_potassium(
    req: PotassiumLogCreate,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return await log_potassium(db, current_user["id"], req.model_dump())


@router.post("/ckd/phosphorus")
async def add_phosphorus(
    req: PhosphorusLogCreate,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return await log_phosphorus(db, current_user["id"], req.model_dump())


@router.get("/ckd/dashboard")
async def ckd_dashboard(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    return await get_ckd_dashboard(db, current_user["id"])
