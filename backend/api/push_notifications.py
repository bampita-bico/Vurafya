"""
FCM push notification token registration.
Flutter app registers its FCM token on login/startup.
Backend stores it to send push notifications (medication reminders, alerts, etc.)
"""
from fastapi import APIRouter, Depends
from backend.utils.database import get_db
from backend.utils.dependencies import get_current_user
from backend.utils.exceptions import ValidationError
from backend.models.schemas import RegisterFcmTokenRequest, SendTestPushRequest
from datetime import datetime, timezone

router = APIRouter()


def _now():
    return datetime.now(timezone.utc).isoformat()


@router.post("/register-token")
async def register_fcm_token(
    req: RegisterFcmTokenRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    """Flutter calls this on startup with its FCM token."""
    now = _now()
    user_id = current_user["id"]

    # Upsert FCM token
    cursor = await db.execute(
        "SELECT id FROM device_tokens WHERE user_id = ? AND device_id = ?",
        (user_id, req.device_id),
    )
    existing = await cursor.fetchone()

    if existing:
        await db.execute(
            """UPDATE device_tokens
               SET fcm_token=?, platform=?, app_version=?, updated_at=?
               WHERE user_id=? AND device_id=?""",
            (req.fcm_token, req.platform, req.app_version, now, user_id, req.device_id),
        )
    else:
        await db.execute(
            """INSERT INTO device_tokens
               (user_id, device_id, fcm_token, platform, app_version, is_active, created_at, updated_at)
               VALUES (?,?,?,?,?,1,?,?)""",
            (user_id, req.device_id, req.fcm_token, req.platform, req.app_version, now, now),
        )

    await db.commit()
    return {"registered": True, "device_id": req.device_id}


@router.delete("/unregister-token")
async def unregister_token(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    """Called on logout — deactivates all tokens for this user."""
    await db.execute(
        "UPDATE device_tokens SET is_active = 0 WHERE user_id = ?",
        (current_user["id"],),
    )
    await db.commit()
    return {"unregistered": True}
