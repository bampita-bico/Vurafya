from fastapi import APIRouter, Depends, Query
from backend.utils.database import get_db
from backend.utils.dependencies import get_current_user
from backend.utils.exceptions import NotFoundError, ValidationError
from backend.services.labor_service import (
    get_skill_categories, get_rates_for_country, register_service,
    list_available_workers, get_my_services,
    create_booking, respond_booking, checkin_work, complete_work,
    rate_labor, get_my_bookings, get_earnings_history,
)
from backend.models.schemas import (
    RegisterLaborServiceRequest, CreateLaborBookingRequest,
    RespondBookingRequest, CompleteWorkRequest, RateLaborRequest,
)

router = APIRouter()


# ── Skill catalog ─────────────────────────────────────────────────────────────

@router.get("/skills")
async def skill_categories(db=Depends(get_db)):
    return {"skills": await get_skill_categories(db)}


@router.get("/rates/{country_code}")
async def rates_by_country(country_code: str, db=Depends(get_db)):
    return {"rates": await get_rates_for_country(db, country_code.upper())}


# ── Provider registry ─────────────────────────────────────────────────────────

@router.post("/register")
async def register(
    req: RegisterLaborServiceRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    result = await register_service(db, current_user["id"], req.model_dump())
    if "error" in result:
        raise ValidationError(result["error"])
    return result


@router.get("/workers")
async def browse_workers(
    service_type: str = Query(default=None),
    district: str = Query(default=None),
    limit: int = Query(20, le=100),
    offset: int = Query(0, ge=0),
    db=Depends(get_db),
):
    return {"workers": await list_available_workers(
        db, {"service_type": service_type, "district": district, "limit": limit, "offset": offset}
    )}


@router.get("/my-services")
async def my_services(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    return {"services": await get_my_services(db, current_user["id"])}


# ── Booking lifecycle ─────────────────────────────────────────────────────────

@router.post("/bookings")
async def book_worker(
    req: CreateLaborBookingRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    result = await create_booking(db, current_user["id"], req.model_dump())
    if "error" in result:
        raise ValidationError(result["error"])
    return result


@router.post("/bookings/{booking_id}/respond")
async def respond(
    booking_id: int,
    req: RespondBookingRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    result = await respond_booking(db, current_user["id"], booking_id, req.accept)
    if "error" in result:
        raise ValidationError(result["error"])
    return result


@router.post("/bookings/{booking_id}/checkin")
async def checkin(
    booking_id: int,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    result = await checkin_work(db, current_user["id"], booking_id, {})
    if "error" in result:
        raise ValidationError(result["error"])
    return result


@router.post("/bookings/{booking_id}/complete")
async def complete(
    booking_id: int,
    req: CompleteWorkRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    result = await complete_work(db, current_user["id"], booking_id, req.model_dump())
    if "error" in result:
        raise ValidationError(result["error"])
    return result


@router.post("/bookings/{booking_id}/rate")
async def rate_booking(
    booking_id: int,
    req: RateLaborRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    result = await rate_labor(db, current_user["id"], booking_id, req.model_dump())
    if "error" in result:
        raise ValidationError(result["error"])
    return result


@router.get("/bookings")
async def my_bookings(
    role: str = Query(default="all", description="all | provider | requester"),
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return {"bookings": await get_my_bookings(db, current_user["id"], role)}


@router.get("/earnings")
async def earnings(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    return {"earnings": await get_earnings_history(db, current_user["id"])}
