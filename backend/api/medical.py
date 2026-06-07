from fastapi import APIRouter, Depends, Query
from backend.utils.database import get_db
from backend.utils.dependencies import get_current_user
from backend.utils.exceptions import NotFoundError, ValidationError
from backend.services.medical_service import (
    search_doctors, get_doctor_detail,
    book_consultation, get_user_bookings, cancel_booking,
    create_lab_order, get_user_lab_orders, get_lab_tests,
    get_user_receipts,
)
from backend.models.schemas import (
    ConsultationBookRequest, LabOrderCreate, CancelBookingRequest,
)

router = APIRouter()


# ── Doctors ─────────────────────────────────────────────────────────────────

@router.get("/doctors")
async def list_doctors(
    specialty: str = Query(default=None),
    country: str = Query(default=None),
    limit: int = Query(20, le=100),
    offset: int = Query(0, ge=0),
    db=Depends(get_db),
):
    return await search_doctors(db, specialty, country, limit, offset)


@router.get("/doctors/{doctor_id}")
async def doctor_detail(doctor_id: int, db=Depends(get_db)):
    result = await get_doctor_detail(db, doctor_id)
    if not result:
        raise NotFoundError("Doctor", doctor_id)
    return result


# ── Consultations ────────────────────────────────────────────────────────────

@router.post("/consultations/book")
async def book(
    req: ConsultationBookRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    result = await book_consultation(db, current_user["id"], req.model_dump())
    if "error" in result:
        raise ValidationError(result["error"])
    return result


@router.get("/consultations")
async def my_consultations(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    return {"consultations": await get_user_bookings(db, current_user["id"])}


@router.post("/consultations/{booking_id}/cancel")
async def cancel(
    booking_id: int,
    req: CancelBookingRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    result = await cancel_booking(db, current_user["id"], booking_id, req.reason)
    if "error" in result:
        raise NotFoundError("Booking", booking_id)
    return result


# ── Lab tests + orders ───────────────────────────────────────────────────────

@router.get("/lab/tests")
async def lab_catalog(
    category: str = Query(default=None),
    db=Depends(get_db),
):
    return {"tests": await get_lab_tests(db, category)}


@router.post("/lab/orders")
async def create_order(
    req: LabOrderCreate,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return await create_lab_order(db, current_user["id"], req.model_dump())


@router.get("/lab/orders")
async def my_lab_orders(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    return {"orders": await get_user_lab_orders(db, current_user["id"])}


# ── Receipts ─────────────────────────────────────────────────────────────────

@router.get("/receipts")
async def my_receipts(
    limit: int = Query(20, le=100),
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return {"receipts": await get_user_receipts(db, current_user["id"], limit)}
