from fastapi import APIRouter, Depends, Query
from backend.utils.database import get_db
from backend.utils.dependencies import get_current_user
from backend.utils.exceptions import NotFoundError, ValidationError
from backend.services.pharmacy_service import (
    search_medications, get_medication_detail,
    get_user_schedules, create_schedule, deactivate_schedule,
    log_adherence, get_adherence_history,
    get_user_orders,
)
from backend.models.schemas import (
    MedicationScheduleCreate, AdherenceLogCreate,
)

router = APIRouter()


# ── Medications catalog ─────────────────────────────────────────────────────

@router.get("/medications/search")
async def search_meds(
    q: str = Query(..., min_length=1),
    limit: int = Query(20, le=100),
    offset: int = Query(0, ge=0),
    db=Depends(get_db),
):
    return await search_medications(db, q, limit, offset)


@router.get("/medications/{med_id}")
async def med_detail(med_id: int, db=Depends(get_db)):
    result = await get_medication_detail(db, med_id)
    if not result:
        raise NotFoundError("Medication", med_id)
    return result


# ── Medication schedules ────────────────────────────────────────────────────

@router.get("/schedules")
async def my_schedules(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    return {"schedules": await get_user_schedules(db, current_user["id"])}


@router.post("/schedules")
async def add_schedule(
    req: MedicationScheduleCreate,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return await create_schedule(db, current_user["id"], req.model_dump())


@router.delete("/schedules/{schedule_id}")
async def remove_schedule(
    schedule_id: int,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    ok = await deactivate_schedule(db, current_user["id"], schedule_id)
    if not ok:
        raise NotFoundError("Schedule", schedule_id)
    return {"status": "deactivated"}


# ── Adherence ───────────────────────────────────────────────────────────────

@router.post("/adherence")
async def log_dose(
    req: AdherenceLogCreate,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return await log_adherence(db, current_user["id"], req.model_dump())


@router.get("/adherence")
async def adherence_history(
    days: int = Query(7, ge=1, le=90),
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return await get_adherence_history(db, current_user["id"], days)


# ── Orders ──────────────────────────────────────────────────────────────────

@router.get("/orders")
async def my_orders(
    limit: int = Query(20, le=100),
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return {"orders": await get_user_orders(db, current_user["id"], limit)}
