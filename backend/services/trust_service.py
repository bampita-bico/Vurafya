import aiosqlite
import json
from datetime import datetime, timezone


def _now():
    return datetime.now(timezone.utc).isoformat()


# ---------------------------------------------------------------------------
# KYC
# ---------------------------------------------------------------------------

async def get_kyc_status(db: aiosqlite.Connection, user_id: int) -> dict | None:
    cursor = await db.execute(
        "SELECT * FROM user_kyc_status WHERE user_id = ?", (user_id,)
    )
    return await cursor.fetchone()


async def submit_kyc(db: aiosqlite.Connection, user_id: int, data: dict) -> dict:
    now = _now()
    existing = await get_kyc_status(db, user_id)

    tier = data.get("kyc_tier", 1)
    tier_labels = {0: "none", 1: "basic", 2: "intermediate", 3: "full"}
    tier_limits = {0: 10_000, 1: 500_000, 2: 5_000_000, 3: 999_999_999}
    tier_monthly = {0: 100_000, 1: 5_000_000, 2: 20_000_000, 3: 999_999_999}

    if existing:
        await db.execute(
            """UPDATE user_kyc_status SET
               kyc_tier=?, kyc_level=?,
               has_verified_phone=?, has_provided_full_name=?, has_provided_dob=?,
               has_national_id=?, national_id_verified=?,
               has_proof_of_address=?,
               has_tax_id=?, has_bank_verification=?,
               max_transaction_ugx=?, max_monthly_volume_ugx=?,
               kyc_documents=?, updated_at=?
               WHERE user_id=?""",
            (
                tier, tier_labels.get(tier, "basic"),
                data.get("has_verified_phone", False),
                data.get("has_provided_full_name", False),
                data.get("has_provided_dob", False),
                data.get("has_national_id", False),
                data.get("national_id_verified", False),
                data.get("has_proof_of_address", False),
                data.get("has_tax_id", False),
                data.get("has_bank_verification", False),
                tier_limits[tier],
                tier_monthly[tier],
                json.dumps(data.get("documents", [])),
                now, user_id,
            ),
        )
    else:
        await db.execute(
            """INSERT INTO user_kyc_status
               (user_id, kyc_tier, kyc_level,
                has_verified_phone, has_provided_full_name, has_provided_dob,
                has_national_id, national_id_verified, has_proof_of_address,
                has_tax_id, has_bank_verification,
                max_transaction_ugx, max_monthly_volume_ugx,
                kyc_documents, created_at, updated_at)
               VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
            (
                user_id, tier, tier_labels.get(tier, "basic"),
                data.get("has_verified_phone", False),
                data.get("has_provided_full_name", False),
                data.get("has_provided_dob", False),
                data.get("has_national_id", False),
                data.get("national_id_verified", False),
                data.get("has_proof_of_address", False),
                data.get("has_tax_id", False),
                data.get("has_bank_verification", False),
                tier_limits[tier],
                tier_monthly[tier],
                json.dumps(data.get("documents", [])),
                now, now,
            ),
        )
    await db.commit()
    return {
        "user_id": user_id,
        "kyc_tier": tier,
        "kyc_level": tier_labels.get(tier, "basic"),
        "max_transaction_ugx": tier_limits[tier],
        "status": "submitted",
    }


# ---------------------------------------------------------------------------
# Notifications
# ---------------------------------------------------------------------------

async def get_notifications(db: aiosqlite.Connection, user_id: int, unread_only: bool = False) -> list:
    q = "SELECT * FROM notifications WHERE user_id = ?"
    params = [user_id]
    if unread_only:
        q += " AND is_read = 0"
    q += " ORDER BY created_at DESC LIMIT 50"
    cursor = await db.execute(q, params)
    return await cursor.fetchall()


async def mark_read(db: aiosqlite.Connection, user_id: int, notification_id: int) -> dict:
    await db.execute(
        "UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?",
        (notification_id, user_id),
    )
    await db.commit()
    return {"marked_read": notification_id}


async def mark_all_read(db: aiosqlite.Connection, user_id: int) -> dict:
    cursor = await db.execute(
        "UPDATE notifications SET is_read = 1 WHERE user_id = ? AND is_read = 0",
        (user_id,),
    )
    await db.commit()
    return {"marked_count": cursor.rowcount}


async def get_notification_prefs(db: aiosqlite.Connection, user_id: int) -> dict | None:
    cursor = await db.execute(
        "SELECT * FROM notification_preferences WHERE user_id = ?", (user_id,)
    )
    row = await cursor.fetchone()
    if not row:
        # Create defaults
        now = _now()
        await db.execute(
            "INSERT INTO notification_preferences (user_id, meal_reminders, challenge_updates, medical_alerts, created_at) VALUES (?,1,1,1,?)",
            (user_id, now),
        )
        await db.commit()
        cursor = await db.execute(
            "SELECT * FROM notification_preferences WHERE user_id = ?", (user_id,)
        )
        row = await cursor.fetchone()
    return row


async def update_notification_prefs(db: aiosqlite.Connection, user_id: int, data: dict) -> dict:
    now = _now()
    existing = await get_notification_prefs(db, user_id)
    if existing:
        await db.execute(
            """UPDATE notification_preferences
               SET meal_reminders=?, challenge_updates=?, medical_alerts=?
               WHERE user_id=?""",
            (
                data.get("meal_reminders", existing["meal_reminders"]),
                data.get("challenge_updates", existing["challenge_updates"]),
                data.get("medical_alerts", existing["medical_alerts"]),
                user_id,
            ),
        )
        await db.commit()
    return {"updated": True}
