import aiosqlite
from datetime import datetime, timezone


# ---------------------------------------------------------------------------
# Doctors
# ---------------------------------------------------------------------------

async def search_doctors(
    db: aiosqlite.Connection,
    specialty: str | None = None,
    country: str | None = None,
    limit: int = 20,
    offset: int = 0,
) -> dict:
    conditions = ["dp.is_active = TRUE", "dp.is_verified = TRUE"]
    params: list = []

    if specialty:
        conditions.append("dp.specialty_id IN (SELECT id FROM doctor_medical_specialties WHERE specialty_name LIKE ?)")
        params.append(f"%{specialty}%")
    if country:
        conditions.append("dp.country_code = ?")
        params.append(country)

    where = " AND ".join(conditions)
    params += [limit, offset]

    cursor = await db.execute(
        f"""SELECT dp.id, dp.full_name, dp.title, dp.years_experience,
                   dp.consultation_fee_ugx, dp.consultation_fee_usd,
                   dp.average_rating, dp.total_consultations,
                   dp.is_available_for_telehealth, dp.city, dp.country_code,
                   dp.response_time_avg_minutes, dp.bio
            FROM doctor_profiles dp
            WHERE {where}
            ORDER BY dp.average_rating DESC, dp.total_consultations DESC
            LIMIT ? OFFSET ?""",
        params,
    )
    items = await cursor.fetchall()

    count_params = params[:-2]
    cursor = await db.execute(
        f"SELECT COUNT(*) as total FROM doctor_profiles dp WHERE {where}",
        count_params,
    )
    total = await cursor.fetchone()
    return {"items": items, "total": total["total"], "offset": offset, "limit": limit}


async def get_doctor_detail(db: aiosqlite.Connection, doctor_id: int) -> dict | None:
    cursor = await db.execute("SELECT * FROM doctor_profiles WHERE id = ?", (doctor_id,))
    doc = await cursor.fetchone()
    if not doc:
        return None

    # Availability slots
    cursor = await db.execute(
        """SELECT * FROM doctor_availability_slots
           WHERE doctor_profile_id = ? AND is_available = TRUE AND slot_start > datetime('now')
           ORDER BY slot_start
           LIMIT 20""",
        (doctor_id,),
    )
    slots = await cursor.fetchall()

    return {"doctor": doc, "available_slots": slots}


# ---------------------------------------------------------------------------
# Consultation bookings
# ---------------------------------------------------------------------------

async def book_consultation(db: aiosqlite.Connection, user_id: int, data: dict) -> dict:
    now = datetime.now(timezone.utc).isoformat()

    # Get doctor fee
    cursor = await db.execute(
        "SELECT consultation_fee_ugx, consultation_fee_usd FROM doctor_profiles WHERE id = ? AND is_active = TRUE",
        (data["doctor_profile_id"],),
    )
    doc = await cursor.fetchone()
    if not doc:
        return {"error": "Doctor not found"}

    # Get user tier for commission
    cursor = await db.execute(
        """SELECT COALESCE(sp.tier, 1) as tier FROM users u
           LEFT JOIN user_subscriptions us ON u.id = us.user_id AND us.status IN ('active', 'trial')
           LEFT JOIN subscription_plans sp ON us.plan_id = sp.id
           WHERE u.id = ?""",
        (user_id,),
    )
    tier_row = await cursor.fetchone()
    tier = tier_row["tier"] if tier_row else 1

    fee_ugx = doc["consultation_fee_ugx"] or 0
    platform_pct = 0.20 if tier == 1 else (0.15 if tier == 2 else 0.12)
    platform_ugx = round(fee_ugx * platform_pct, 0)
    doctor_payout = round(fee_ugx - platform_ugx, 0)

    cursor = await db.execute(
        """INSERT INTO consultation_bookings
           (patient_user_id, doctor_profile_id, consultation_type, booking_source,
            scheduled_at, duration_minutes, status, consultation_fee_ugx,
            consultation_fee_usd, currency_code, platform_commission_pct,
            platform_commission_ugx, doctor_payout_ugx, patient_subscription_tier,
            is_priority, payment_method, payment_status, chief_complaint, notes,
            created_at, updated_at)
           VALUES (?, ?, ?, 'app', ?, ?, 'pending', ?, ?, 'UGX', ?, ?, ?, ?, ?, ?, 'pending', ?, ?, ?, ?)""",
        (
            user_id,
            data["doctor_profile_id"],
            data.get("consultation_type", "telehealth"),
            data["scheduled_at"],
            data.get("duration_minutes", 30),
            fee_ugx,
            doc["consultation_fee_usd"],
            platform_pct,
            platform_ugx,
            doctor_payout,
            tier,
            data.get("is_priority", False),
            data.get("payment_method", "mobile_money"),
            data.get("chief_complaint"),
            data.get("notes"),
            now, now,
        ),
    )
    booking_id = cursor.lastrowid
    await db.commit()

    return {
        "booking_id": booking_id,
        "status": "pending",
        "fee_ugx": fee_ugx,
        "platform_commission_ugx": platform_ugx,
        "doctor_payout_ugx": doctor_payout,
        "scheduled_at": data["scheduled_at"],
    }


async def get_user_bookings(db: aiosqlite.Connection, user_id: int) -> list:
    cursor = await db.execute(
        """SELECT cb.*, dp.full_name as doctor_name, dp.title as doctor_title
           FROM consultation_bookings cb
           JOIN doctor_profiles dp ON cb.doctor_profile_id = dp.id
           WHERE cb.patient_user_id = ?
           ORDER BY cb.scheduled_at DESC""",
        (user_id,),
    )
    return await cursor.fetchall()


async def cancel_booking(db: aiosqlite.Connection, user_id: int, booking_id: int, reason: str) -> dict:
    now = datetime.now(timezone.utc).isoformat()
    result = await db.execute(
        """UPDATE consultation_bookings
           SET status = 'cancelled', cancelled_at = ?, cancellation_reason = ?, cancelled_by = 'patient', updated_at = ?
           WHERE id = ? AND patient_user_id = ? AND status IN ('pending', 'confirmed')""",
        (now, reason, now, booking_id, user_id),
    )
    await db.commit()
    if result.rowcount == 0:
        return {"error": "Booking not found or cannot be cancelled"}
    return {"booking_id": booking_id, "status": "cancelled"}


# ---------------------------------------------------------------------------
# Lab orders
# ---------------------------------------------------------------------------

async def create_lab_order(db: aiosqlite.Connection, user_id: int, data: dict) -> dict:
    import json
    now = datetime.now(timezone.utc).isoformat()
    test_ids_json = json.dumps(data.get("test_ids", []))

    # Calculate total cost
    total_cost = 0
    for tid in data.get("test_ids", []):
        cursor = await db.execute("SELECT typical_price_ugx FROM lab_test_catalog WHERE id = ?", (tid,))
        row = await cursor.fetchone()
        if row and row["typical_price_ugx"]:
            total_cost += row["typical_price_ugx"]

    cursor = await db.execute(
        """INSERT INTO lab_orders
           (user_id, consultation_id, facility_id, test_ids, order_date,
            status, priority, fasting_status, total_cost_ugx, payment_status, notes, created_at)
           VALUES (?, ?, ?, ?, date('now'), 'pending', ?, ?, ?, 'pending', ?, ?)""",
        (
            user_id,
            data.get("consultation_id"),
            data.get("facility_id"),
            test_ids_json,
            data.get("priority", "routine"),
            data.get("fasting_status", "not_required"),
            total_cost,
            data.get("notes"),
            now,
        ),
    )
    await db.commit()
    return {"order_id": cursor.lastrowid, "total_cost_ugx": total_cost, "test_count": len(data.get("test_ids", []))}


async def get_user_lab_orders(db: aiosqlite.Connection, user_id: int) -> list:
    cursor = await db.execute(
        "SELECT * FROM lab_orders WHERE user_id = ? ORDER BY order_date DESC",
        (user_id,),
    )
    return await cursor.fetchall()


async def get_lab_tests(db: aiosqlite.Connection, category: str | None = None) -> list:
    if category:
        cursor = await db.execute(
            "SELECT * FROM lab_test_catalog WHERE test_category = ? ORDER BY test_name",
            (category,),
        )
    else:
        cursor = await db.execute("SELECT * FROM lab_test_catalog ORDER BY test_category, test_name")
    return await cursor.fetchall()


# ---------------------------------------------------------------------------
# Receipts
# ---------------------------------------------------------------------------

async def get_user_receipts(db: aiosqlite.Connection, user_id: int, limit: int = 20) -> list:
    cursor = await db.execute(
        """SELECT * FROM consultation_receipts
           WHERE payer_user_id = ? AND voided = FALSE
           ORDER BY transaction_date DESC
           LIMIT ?""",
        (user_id, limit),
    )
    return await cursor.fetchall()
