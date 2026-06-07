from fastapi import APIRouter, Depends, Query
from backend.utils.database import get_db
from backend.utils.dependencies import get_current_user
from backend.utils.exceptions import NotFoundError, ValidationError
from backend.services.trust_service import (
    get_trust_profile, recalculate_trust,
    get_kyc_status, submit_kyc,
    get_notifications, mark_read, mark_all_read,
    get_notification_prefs, update_notification_prefs,
)
from backend.models.schemas import (
    SubmitKycRequest, UpdateNotificationPrefsRequest,
)

router = APIRouter()


# ── Trust scores ─────────────────────────────────────────────────────────────

@router.get("/trust/me")
async def my_trust(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    profile = await get_trust_profile(db, current_user["id"])
    if not profile:
        return await recalculate_trust(db, current_user["id"])
    return profile


@router.get("/trust/{user_id}")
async def user_trust(user_id: int, db=Depends(get_db)):
    profile = await get_trust_profile(db, user_id)
    if not profile:
        raise NotFoundError("Trust profile", user_id)
    return {
        "user_id": user_id,
        "trust_score": profile["trust_score"],
        "trust_level": profile["trust_level"],
        "badges": {
            "verified_trader": profile["has_verified_trader_badge"],
            "reliable_worker": profile["has_reliable_worker_badge"],
            "honest_trader": profile["has_honest_trader_badge"],
            "prompt_payer": profile["has_prompt_payer_badge"],
        },
        "max_transaction_ugx": profile["max_transaction_ugx"],
        "requires_escrow": profile["requires_escrow"],
    }


@router.post("/trust/recalculate")
async def recalculate(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    return await recalculate_trust(db, current_user["id"])


# ── KYC ──────────────────────────────────────────────────────────────────────

@router.get("/kyc")
async def my_kyc(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    status = await get_kyc_status(db, current_user["id"])
    if not status:
        return {"user_id": current_user["id"], "kyc_tier": 0, "kyc_level": "none"}
    return status


@router.post("/kyc")
async def submit(
    req: SubmitKycRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return await submit_kyc(db, current_user["id"], req.model_dump())


# ── Notifications ─────────────────────────────────────────────────────────────

@router.get("/notifications")
async def notifications(
    unread_only: bool = Query(default=False),
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return {"notifications": await get_notifications(db, current_user["id"], unread_only)}


@router.post("/notifications/{notification_id}/read")
async def read_one(
    notification_id: int,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return await mark_read(db, current_user["id"], notification_id)


@router.post("/notifications/read-all")
async def read_all(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    return await mark_all_read(db, current_user["id"])


@router.get("/notifications/preferences")
async def notif_prefs(current_user: dict = Depends(get_current_user), db=Depends(get_db)):
    return await get_notification_prefs(db, current_user["id"])


@router.put("/notifications/preferences")
async def update_prefs(
    req: UpdateNotificationPrefsRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    return await update_notification_prefs(db, current_user["id"], req.model_dump())
