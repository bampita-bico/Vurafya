from fastapi import APIRouter, Depends, Query
from backend.utils.database import get_db
from backend.utils.dependencies import get_current_user
from backend.utils.exceptions import ValidationError
from backend.services.trust_service import (
    get_kyc_status, submit_kyc,
    get_notifications, mark_read, mark_all_read,
    get_notification_prefs, update_notification_prefs,
)
from backend.models.schemas import (
    SubmitKycRequest, UpdateNotificationPrefsRequest,
)

router = APIRouter()


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
