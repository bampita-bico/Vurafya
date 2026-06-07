from fastapi import APIRouter, Depends, Query
from backend.utils.database import get_db
from backend.utils.dependencies import get_current_user
from backend.utils.exceptions import ValidationError
from backend.services.payments_service import (
    get_vrc_wallet, convert_ap_to_vrc, send_vrc,
    get_payment_history, initiate_payment,
)
from backend.models.schemas import (
    ApToVrcRequest, SendVrcRequest, InitiatePaymentRequest,
)

router = APIRouter()


# ── VRC wallet ───────────────────────────────────────────────────────────────

@router.get("/vrc/wallet")
async def my_wallet(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    return await get_vrc_wallet(db, current_user["id"])


@router.post("/vrc/convert-ap")
async def ap_to_vrc(
    req: ApToVrcRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    result = await convert_ap_to_vrc(db, current_user["id"], req.ap_amount)
    if "error" in result:
        raise ValidationError(result["error"])
    return result


@router.post("/vrc/send")
async def send(
    req: SendVrcRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    result = await send_vrc(db, current_user["id"], req.model_dump())
    if "error" in result:
        raise ValidationError(result["error"])
    return result


# ── Unified payment ledger ────────────────────────────────────────────────────

@router.get("/history")
async def payment_history(
    limit: int = Query(20, le=100),
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return {"payments": await get_payment_history(db, current_user["id"], limit)}


@router.post("/initiate")
async def initiate(
    req: InitiatePaymentRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return await initiate_payment(db, current_user["id"], req.model_dump())
