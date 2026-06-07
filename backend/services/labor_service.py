import aiosqlite
import json
from datetime import datetime, timezone


def _now():
    return datetime.now(timezone.utc).isoformat()


# ---------------------------------------------------------------------------
# Skill categories + rates
# ---------------------------------------------------------------------------

async def get_skill_categories(db: aiosqlite.Connection) -> list:
    cursor = await db.execute(
        "SELECT * FROM labor_skill_categories WHERE is_active = 1 ORDER BY skill_tier, category_name"
    )
    return await cursor.fetchall()


async def get_rates_for_country(db: aiosqlite.Connection, country_code: str) -> list:
    cursor = await db.execute(
        """SELECT lcc.*, lsc.category_name, lsc.skill_tier
           FROM labor_currency_conversion lcc
           JOIN labor_skill_categories lsc ON lcc.skill_category_id = lsc.id
           WHERE lcc.country_code = ? AND lcc.is_active = 1
           ORDER BY lsc.skill_tier, lsc.category_name""",
        (country_code,),
    )
    return await cursor.fetchall()


# ---------------------------------------------------------------------------
# Provider registry
# ---------------------------------------------------------------------------

async def register_service(db: aiosqlite.Connection, user_id: int, data: dict) -> dict:
    now = _now()

    # Validate skill category exists
    cursor = await db.execute(
        "SELECT id, base_hourly_rate_ap, base_hourly_rate_ugx FROM labor_skill_categories WHERE id = ?",
        (data["skill_category_id"],),
    )
    skill = await cursor.fetchone()
    if not skill:
        return {"error": "Invalid skill category"}

    proficiency = data.get("proficiency_level", "intermediate")
    multipliers = {"beginner": 0.7, "intermediate": 1.0, "advanced": 1.3, "expert": 1.5}
    mult = multipliers.get(proficiency, 1.0)
    rate_ap = int(skill["base_hourly_rate_ap"] * mult)
    rate_ugx = skill["base_hourly_rate_ugx"] * mult

    cursor = await db.execute(
        """INSERT INTO labor_services_registry
           (user_id, service_type, service_name, service_description,
            proficiency_level, years_experience, certifications,
            hourly_rate_afya_points, hourly_rate_ugx,
            min_hours, max_hours_per_week, rate_negotiable,
            location_district, can_travel, travel_radius_km,
            is_available, background_check_status, preferred_payment_method,
            accepts_barter, created_at, updated_at)
           VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,1,'not_required','afya_points',0,?,?)""",
        (
            user_id,
            data.get("service_type"),
            data["service_name"],
            data.get("service_description"),
            proficiency,
            data.get("years_experience", 0),
            json.dumps(data.get("certifications", [])),
            rate_ap,
            rate_ugx,
            data.get("min_hours", 1),
            data.get("max_hours_per_week", 40),
            data.get("rate_negotiable", True),
            data.get("location_district"),
            data.get("can_travel", False),
            data.get("travel_radius_km", 0),
            now, now,
        ),
    )
    await db.commit()
    return {"service_id": cursor.lastrowid, "hourly_rate_ap": rate_ap, "hourly_rate_ugx": rate_ugx}


async def list_available_workers(db: aiosqlite.Connection, filters: dict) -> list:
    q = """SELECT lr.*, u.username, u.display_name
           FROM labor_services_registry lr
           JOIN users u ON lr.user_id = u.id
           WHERE lr.is_available = 1"""
    params = []
    if filters.get("service_type"):
        q += " AND lr.service_type = ?"
        params.append(filters["service_type"])
    if filters.get("district"):
        q += " AND lr.location_district = ?"
        params.append(filters["district"])
    q += " ORDER BY lr.rating_avg DESC NULLS LAST LIMIT ? OFFSET ?"
    params += [filters.get("limit", 20), filters.get("offset", 0)]
    cursor = await db.execute(q, params)
    return await cursor.fetchall()


async def get_my_services(db: aiosqlite.Connection, user_id: int) -> list:
    cursor = await db.execute(
        "SELECT * FROM labor_services_registry WHERE user_id = ? ORDER BY created_at DESC",
        (user_id,),
    )
    return await cursor.fetchall()


# ---------------------------------------------------------------------------
# Booking lifecycle
# ---------------------------------------------------------------------------

async def create_booking(db: aiosqlite.Connection, requester_id: int, data: dict) -> dict:
    now = _now()

    cursor = await db.execute(
        "SELECT * FROM labor_services_registry WHERE id = ? AND is_available = 1",
        (data["labor_service_id"],),
    )
    service = await cursor.fetchone()
    if not service:
        return {"error": "Service not found or unavailable"}
    if service["user_id"] == requester_id:
        return {"error": "Cannot book your own service"}

    hours = data["hours_requested"]
    rate_ap = service["hourly_rate_afya_points"]
    total_ap = int(hours * rate_ap)

    # Fee: 5% on worker
    fee_pct = 5.0
    cursor = await db.execute(
        "SELECT rate_pct FROM fee_structure_config WHERE fee_type = 'labor_transaction'"
    )
    fee_row = await cursor.fetchone()
    if fee_row:
        fee_pct = fee_row["rate_pct"]

    cursor = await db.execute(
        """INSERT INTO labor_booking_requests
           (requester_user_id, labor_service_id, provider_user_id,
            hours_requested, hourly_rate_ap, total_cost_ap,
            booking_date, start_time, end_time,
            work_location_address, work_description,
            payment_method, status,
            transaction_fee_pct, transaction_fee_ap, platform_revenue_ugx,
            requested_at, created_at, updated_at)
           VALUES (?,?,?,?,?,?,?,?,?,?,?,'afya_points','pending',?,?,?,?,?,?)""",
        (
            requester_id,
            data["labor_service_id"],
            service["user_id"],
            hours,
            rate_ap,
            total_ap,
            data["booking_date"],
            data.get("start_time", "08:00"),
            data.get("end_time", ""),
            data.get("work_location_address", ""),
            data.get("work_description", ""),
            fee_pct,
            int(total_ap * fee_pct / 100),
            int(total_ap * fee_pct / 100) * 100,   # AP -> UGX
            now, now, now,
        ),
    )
    await db.commit()
    return {
        "booking_id": cursor.lastrowid,
        "total_cost_ap": total_ap,
        "fee_pct": fee_pct,
        "net_to_worker_ap": total_ap - int(total_ap * fee_pct / 100),
    }


async def respond_booking(db: aiosqlite.Connection, provider_id: int, booking_id: int, accept: bool) -> dict:
    now = _now()
    cursor = await db.execute(
        "SELECT * FROM labor_booking_requests WHERE id = ? AND provider_user_id = ?",
        (booking_id, provider_id),
    )
    booking = await cursor.fetchone()
    if not booking:
        return {"error": "Booking not found"}
    if booking["status"] != "pending":
        return {"error": f"Booking already in status: {booking['status']}"}

    new_status = "accepted" if accept else "cancelled"
    extra = (", accepted_at=?" if accept else ", cancelled_at=?")
    await db.execute(
        f"UPDATE labor_booking_requests SET status=?{extra}, updated_at=? WHERE id=?",
        (new_status, now, now, booking_id),
    )
    await db.commit()
    return {"booking_id": booking_id, "status": new_status}


async def checkin_work(db: aiosqlite.Connection, provider_id: int, booking_id: int, data: dict) -> dict:
    now = _now()
    cursor = await db.execute(
        "SELECT * FROM labor_booking_requests WHERE id = ? AND provider_user_id = ?",
        (booking_id, provider_id),
    )
    booking = await cursor.fetchone()
    if not booking:
        return {"error": "Booking not found"}
    if booking["status"] != "accepted":
        return {"error": "Booking not accepted"}

    await db.execute(
        "UPDATE labor_booking_requests SET status='in_progress', started_at=?, updated_at=? WHERE id=?",
        (now, now, booking_id),
    )
    await db.commit()
    return {"booking_id": booking_id, "checked_in_at": now}


async def complete_work(db: aiosqlite.Connection, verifier_id: int, booking_id: int, data: dict) -> dict:
    """Requester confirms work is done; triggers payment."""
    now = _now()
    cursor = await db.execute(
        "SELECT * FROM labor_booking_requests WHERE id = ? AND requester_user_id = ?",
        (booking_id, verifier_id),
    )
    booking = await cursor.fetchone()
    if not booking:
        return {"error": "Booking not found"}
    if booking["status"] != "in_progress":
        return {"error": "Work not in progress"}

    actual_hours = data.get("actual_hours", booking["hours_requested"])
    total_earned = int(actual_hours * booking["hourly_rate_ap"])
    fee_ap = int(total_earned * (booking["transaction_fee_pct"] or 5.0) / 100)
    net_ap = total_earned - fee_ap

    await db.execute(
        "UPDATE labor_booking_requests SET status='completed', completed_at=?, updated_at=? WHERE id=?",
        (now, now, booking_id),
    )

    # Insert into labor_hour_ledger
    await db.execute(
        """INSERT INTO labor_hour_ledger
           (user_id, labor_service_id, labor_booking_id, service_type,
            hours_worked, hourly_rate_ap, total_earned_ap, total_earned_ugx,
            work_date, actual_duration_hours, client_user_id,
            work_location_address, work_description,
            is_verified, payment_status, payment_method,
            transaction_fee_pct, transaction_fee_ap, net_earned_ap, platform_revenue_ugx,
            created_at, updated_at)
           VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,1,'paid','afya_points',?,?,?,?,?,?)""",
        (
            booking["provider_user_id"],
            booking["labor_service_id"],
            booking_id,
            "labor",
            actual_hours,
            booking["hourly_rate_ap"],
            total_earned,
            total_earned * 100,
            booking["booking_date"],
            actual_hours,
            verifier_id,
            booking["work_location_address"],
            booking["work_description"],
            booking["transaction_fee_pct"],
            fee_ap,
            net_ap,
            fee_ap * 100,   # UGX
            now, now,
        ),
    )

    # Credit worker AP
    await db.execute(
        "UPDATE avatar_stats SET afya_points_balance = afya_points_balance + ? WHERE user_id = ?",
        (net_ap, booking["provider_user_id"]),
    )

    # Log platform revenue
    await db.execute(
        """INSERT INTO platform_revenue_ledger
           (revenue_type, source_transaction_id, source_transaction_type,
            gross_amount_ugx, fee_amount_ugx, net_amount_ugx,
            payment_method, status, created_at, updated_at)
           VALUES ('labor_fee', ?, 'labor_booking', ?, ?, ?, 'afya_points', 'credited', ?, ?)""",
        (booking_id, fee_ap * 100, fee_ap * 100, fee_ap * 100, now, now),
    )
    await db.commit()
    return {
        "booking_id": booking_id,
        "status": "completed",
        "total_earned_ap": total_earned,
        "fee_ap": fee_ap,
        "net_to_worker_ap": net_ap,
    }


async def rate_labor(db: aiosqlite.Connection, user_id: int, booking_id: int, data: dict) -> dict:
    now = _now()
    cursor = await db.execute(
        "SELECT * FROM labor_booking_requests WHERE id = ?", (booking_id,)
    )
    booking = await cursor.fetchone()
    if not booking or booking["status"] != "completed":
        return {"error": "Can only rate completed bookings"}

    rating = max(1, min(5, data.get("rating", 5)))
    review = data.get("review", "")

    if user_id == booking["requester_user_id"]:
        await db.execute(
            "UPDATE labor_booking_requests SET requester_rating=?, requester_review=?, updated_at=? WHERE id=?",
            (rating, review, now, booking_id),
        )
        reviewee = booking["provider_user_id"]
    elif user_id == booking["provider_user_id"]:
        await db.execute(
            "UPDATE labor_booking_requests SET provider_rating=?, provider_review=?, updated_at=? WHERE id=?",
            (rating, review, now, booking_id),
        )
        reviewee = booking["requester_user_id"]
    else:
        return {"error": "Not a party to this booking"}

    await db.execute(
        """INSERT INTO transaction_reviews
           (transaction_id, transaction_type, reviewer_user_id, reviewee_user_id,
            rating, review_text, reliability_rating, quality_rating,
            showed_up_on_time, work_completed_fully, is_verified_review, created_at)
           VALUES (?, 'labor', ?, ?, ?, ?, ?, ?, ?, 1, 0, ?)""",
        (
            booking_id, user_id, reviewee, rating, review,
            data.get("reliability_rating", rating),
            data.get("quality_rating", rating),
            data.get("showed_up_on_time", True),
            now,
        ),
    )
    await db.commit()
    return {"rated": True, "rating": rating}


async def get_my_bookings(db: aiosqlite.Connection, user_id: int, role: str = "all") -> list:
    if role == "provider":
        q = "SELECT * FROM labor_booking_requests WHERE provider_user_id = ? ORDER BY created_at DESC"
    elif role == "requester":
        q = "SELECT * FROM labor_booking_requests WHERE requester_user_id = ? ORDER BY created_at DESC"
    else:
        q = """SELECT * FROM labor_booking_requests
               WHERE provider_user_id = ? OR requester_user_id = ?
               ORDER BY created_at DESC"""
        cursor = await db.execute(q, (user_id, user_id))
        return await cursor.fetchall()
    cursor = await db.execute(q, (user_id,))
    return await cursor.fetchall()


async def get_earnings_history(db: aiosqlite.Connection, user_id: int) -> list:
    cursor = await db.execute(
        "SELECT * FROM labor_hour_ledger WHERE user_id = ? ORDER BY work_date DESC LIMIT 50",
        (user_id,),
    )
    return await cursor.fetchall()
