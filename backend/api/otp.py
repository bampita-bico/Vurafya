"""
OTP / SMS verification.
Used for: high-risk transactions, phone verification (KYC tier 1), account recovery.
"""
import hashlib
import random
import string
from datetime import datetime, timezone, timedelta
from fastapi import APIRouter, Depends
from backend.utils.database import get_db
from backend.utils.dependencies import get_current_user
from backend.utils.exceptions import ValidationError
from backend.models.schemas import RequestOtpRequest, VerifyOtpRequest
from backend.config import settings

router = APIRouter()


def _now():
    return datetime.now(timezone.utc).isoformat()


def _generate_otp(length: int = 6) -> str:
    return "".join(random.choices(string.digits, k=length))


def _hash_otp(otp: str, user_id: int) -> str:
    return hashlib.sha256(f"{otp}{user_id}{settings.JWT_SECRET}".encode()).hexdigest()


@router.post("/request")
async def request_otp(
    req: RequestOtpRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    now = _now()
    user_id = current_user["id"]
    expires = (datetime.now(timezone.utc) + timedelta(minutes=10)).isoformat()

    # Expire any existing active OTPs for this user/purpose
    await db.execute(
        """UPDATE sms_verification_codes
           SET status='expired'
           WHERE user_id=? AND verification_purpose=? AND status='pending'""",
        (user_id, req.purpose),
    )

    otp = _generate_otp()
    otp_hash = _hash_otp(otp, user_id)

    cursor = await db.execute(
        """INSERT INTO sms_verification_codes
           (user_id, phone_number, otp_code, otp_hash,
            verification_purpose, transaction_id, transaction_type,
            transaction_amount_ugx, status, expires_at,
            sms_provider, max_attempts, verification_attempts, is_locked,
            sent_at, created_at)
           VALUES (?,?,?,?,?,?,?,?,
                   'pending',?,'internal',3,0,0,?,?)""",
        (
            user_id,
            req.phone_number,
            otp,       # In production: don't store plain OTP; send via SMS only
            otp_hash,
            req.purpose,
            req.transaction_id,
            req.transaction_type,
            req.transaction_amount_ugx or 0,
            expires,
            now, now,
        ),
    )
    otp_id = cursor.lastrowid
    await db.commit()

    # In production: send via Twilio/Africa's Talking/infobip
    # For now, return OTP in response (dev mode only)
    response = {"otp_id": otp_id, "expires_at": expires, "phone": req.phone_number}
    if settings.DEBUG:
        response["otp"] = otp  # NEVER expose in production
    return response


@router.post("/verify")
async def verify_otp(
    req: VerifyOtpRequest,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    now = _now()
    user_id = current_user["id"]

    cursor = await db.execute(
        """SELECT * FROM sms_verification_codes
           WHERE id=? AND user_id=? AND status='pending'""",
        (req.otp_id, user_id),
    )
    record = await cursor.fetchone()
    if not record:
        raise ValidationError("OTP not found or already used")

    if record["is_locked"]:
        raise ValidationError("OTP locked due to too many attempts")

    if record["expires_at"] and now > record["expires_at"]:
        await db.execute(
            "UPDATE sms_verification_codes SET status='expired' WHERE id=?",
            (req.otp_id,),
        )
        await db.commit()
        raise ValidationError("OTP expired")

    attempts = (record["verification_attempts"] or 0) + 1
    max_attempts = record["max_attempts"] or 3

    expected_hash = _hash_otp(req.otp_code, user_id)
    if record["otp_hash"] != expected_hash:
        locked = attempts >= max_attempts
        await db.execute(
            """UPDATE sms_verification_codes
               SET verification_attempts=?, is_locked=?, updated_at=?
               WHERE id=?""",
            (attempts, locked, now, req.otp_id),
        )
        await db.commit()
        remaining = max(0, max_attempts - attempts)
        raise ValidationError(f"Invalid OTP. {remaining} attempts remaining.")

    # Mark as verified
    await db.execute(
        "UPDATE sms_verification_codes SET status='verified', verified_at=? WHERE id=?",
        (now, req.otp_id),
    )
    await db.commit()
    return {"verified": True, "purpose": record["verification_purpose"]}
