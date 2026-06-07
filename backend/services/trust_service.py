import aiosqlite
import json
from datetime import datetime, timezone


def _now():
    return datetime.now(timezone.utc).isoformat()


# ---------------------------------------------------------------------------
# Trust score
# ---------------------------------------------------------------------------

async def get_trust_profile(db: aiosqlite.Connection, user_id: int) -> dict | None:
    cursor = await db.execute(
        "SELECT * FROM user_trust_ratings WHERE user_id = ?", (user_id,)
    )
    return await cursor.fetchone()


async def recalculate_trust(db: aiosqlite.Connection, user_id: int) -> dict:
    """Recompute trust score from transaction history."""
    now = _now()

    # Barter reliability: completed / (initiated - disputed) if > 0
    cursor = await db.execute(
        """SELECT
            COUNT(*) as total,
            SUM(CASE WHEN status='completed' THEN 1 ELSE 0 END) as completed,
            SUM(CASE WHEN status='disputed' THEN 1 ELSE 0 END) as disputed,
            SUM(CASE WHEN dispute_raised=1 THEN 1 ELSE 0 END) as dispute_count,
            AVG(CASE WHEN party_a_user_id=? THEN party_b_rating
                     WHEN party_b_user_id=? THEN party_a_rating END) as avg_rating
           FROM barter_exchange_transactions
           WHERE party_a_user_id=? OR party_b_user_id=?""",
        (user_id, user_id, user_id, user_id),
    )
    barter = await cursor.fetchone()

    barter_total = barter["total"] or 0
    barter_completed = barter["completed"] or 0
    barter_reliability = (barter_completed / barter_total) if barter_total > 0 else 0.5

    # Labor reliability: completed / total
    cursor = await db.execute(
        """SELECT
            COUNT(*) as total,
            SUM(CASE WHEN status='completed' THEN 1 ELSE 0 END) as completed,
            SUM(no_show_count) as no_shows
           FROM labor_services_registry WHERE user_id=?""",
        (user_id,),
    )
    labor_row = await cursor.fetchone()

    cursor = await db.execute(
        """SELECT COUNT(*) as bookings,
                  SUM(CASE WHEN status='completed' THEN 1 ELSE 0 END) as done
           FROM labor_booking_requests WHERE provider_user_id=?""",
        (user_id,),
    )
    labor_bookings = await cursor.fetchone()
    labor_total = labor_bookings["bookings"] or 0
    labor_done = labor_bookings["done"] or 0
    labor_reliability = (labor_done / labor_total) if labor_total > 0 else 0.5

    # Payment reliability (from unified_payment_ledger)
    cursor = await db.execute(
        """SELECT COUNT(*) as total,
                  SUM(CASE WHEN payment_status='completed' THEN 1 ELSE 0 END) as completed
           FROM unified_payment_ledger WHERE payer_user_id=?""",
        (user_id,),
    )
    payments = await cursor.fetchone()
    pay_total = payments["total"] or 0
    pay_done = payments["completed"] or 0
    payment_reliability = (pay_done / pay_total) if pay_total > 0 else 0.5

    # Average rating across all reviews
    cursor = await db.execute(
        "SELECT AVG(rating) as avg FROM transaction_reviews WHERE reviewee_user_id=?",
        (user_id,),
    )
    rating_row = await cursor.fetchone()
    avg_rating = rating_row["avg"] or 3.5

    # Verification rate (KYC tier)
    cursor = await db.execute(
        "SELECT kyc_tier FROM user_kyc_status WHERE user_id=?", (user_id,)
    )
    kyc_row = await cursor.fetchone()
    verification_rate = min(1.0, (kyc_row["kyc_tier"] if kyc_row else 0) / 3.0)

    # Dispute / no-show penalties
    dispute_count = barter["dispute_count"] or 0
    no_show_count = (labor_row["no_shows"] if labor_row else 0) or 0

    # Weights from DB (fallback to spec)
    trust_score = (
        barter_reliability * 0.30
        + labor_reliability * 0.30
        + payment_reliability * 0.20
        + verification_rate * 0.10
        + (avg_rating / 5.0) * 0.10
        - 0.05 * dispute_count
        - 0.10 * no_show_count
    )
    trust_score = max(0.0, min(1.0, trust_score))

    # Trust level
    if trust_score < 0.30:
        trust_level = "building"
        max_tx = 10_000
        requires_escrow = True
    elif trust_score < 0.40:
        trust_level = "low"
        max_tx = 50_000
        requires_escrow = True
    elif trust_score < 0.60:
        trust_level = "medium"
        max_tx = 50_000
        requires_escrow = True
    elif trust_score < 0.80:
        trust_level = "high"
        max_tx = 200_000
        requires_escrow = False
    else:
        trust_level = "verified_trader"
        max_tx = 999_999_999
        requires_escrow = False

    # Badges
    has_verified = trust_score >= 0.8
    has_worker = labor_total > 0 and (labor_done / labor_total) >= 0.95
    has_honest = barter_total > 0 and (barter_completed / barter_total) >= 0.95 and dispute_count == 0
    has_prompt = pay_total > 0 and (pay_done / pay_total) >= 0.95

    # Upsert
    existing = await get_trust_profile(db, user_id)
    if existing:
        await db.execute(
            """UPDATE user_trust_ratings SET
               trust_score=?, trust_level=?,
               barter_reliability=?, labor_reliability=?,
               payment_reliability=?, verification_rate=?, avg_rating=?,
               total_transactions=?, completed_transactions=?,
               disputed_transactions=?, barter_trades_initiated=?, barter_trades_completed=?,
               labor_hours_committed=?, labor_no_shows=?,
               has_verified_trader_badge=?, has_reliable_worker_badge=?,
               has_honest_trader_badge=?, has_prompt_payer_badge=?,
               max_transaction_ugx=?, requires_escrow=?,
               last_calculated=?, updated_at=?
               WHERE user_id=?""",
            (
                round(trust_score, 4), trust_level,
                round(barter_reliability, 4), round(labor_reliability, 4),
                round(payment_reliability, 4), round(verification_rate, 4), round(avg_rating, 2),
                barter_total + labor_total + pay_total,
                barter_completed + labor_done + pay_done,
                dispute_count, barter_total, barter_completed,
                labor_total, no_show_count,
                has_verified, has_worker, has_honest, has_prompt,
                max_tx, requires_escrow,
                now, now, user_id,
            ),
        )
    else:
        await db.execute(
            """INSERT INTO user_trust_ratings
               (user_id, trust_score, trust_level,
                barter_reliability, labor_reliability, payment_reliability,
                verification_rate, avg_rating,
                total_transactions, completed_transactions, disputed_transactions,
                barter_trades_initiated, barter_trades_completed, labor_no_shows,
                has_verified_trader_badge, has_reliable_worker_badge,
                has_honest_trader_badge, has_prompt_payer_badge,
                max_transaction_ugx, requires_escrow,
                last_calculated, created_at, updated_at)
               VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
            (
                user_id, round(trust_score, 4), trust_level,
                round(barter_reliability, 4), round(labor_reliability, 4),
                round(payment_reliability, 4), round(verification_rate, 4), round(avg_rating, 2),
                barter_total + labor_total + pay_total,
                barter_completed + labor_done + pay_done,
                dispute_count, barter_total, barter_completed, no_show_count,
                has_verified, has_worker, has_honest, has_prompt,
                max_tx, requires_escrow,
                now, now, now,
            ),
        )
    await db.commit()
    return {
        "user_id": user_id,
        "trust_score": round(trust_score, 4),
        "trust_level": trust_level,
        "max_transaction_ugx": max_tx,
        "requires_escrow": requires_escrow,
        "badges": {
            "verified_trader": has_verified,
            "reliable_worker": has_worker,
            "honest_trader": has_honest,
            "prompt_payer": has_prompt,
        },
    }


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
