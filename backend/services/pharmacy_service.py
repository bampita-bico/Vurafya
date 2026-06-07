import aiosqlite
from datetime import datetime, timezone


# ---------------------------------------------------------------------------
# Medications catalog
# ---------------------------------------------------------------------------

async def search_medications(db: aiosqlite.Connection, query: str, limit: int = 20, offset: int = 0) -> dict:
    q = f"%{query}%"
    cursor = await db.execute(
        """SELECT id, generic_name, brand_name, category, description, requires_prescription, price
           FROM medications
           WHERE generic_name LIKE ? OR brand_name LIKE ?
           ORDER BY generic_name
           LIMIT ? OFFSET ?""",
        (q, q, limit, offset),
    )
    items = await cursor.fetchall()
    cursor = await db.execute(
        "SELECT COUNT(*) as total FROM medications WHERE generic_name LIKE ? OR brand_name LIKE ?",
        (q, q),
    )
    total = await cursor.fetchone()
    return {"items": items, "total": total["total"], "offset": offset, "limit": limit}


async def get_medication_detail(db: aiosqlite.Connection, med_id: int) -> dict | None:
    cursor = await db.execute("SELECT * FROM medications WHERE id = ?", (med_id,))
    med = await cursor.fetchone()
    if not med:
        return None

    # Drug–drug interactions
    cursor = await db.execute(
        """SELECT ddi.*, m2.generic_name as interacting_drug_name
           FROM drug_drug_interactions ddi
           JOIN medications m2 ON ddi.drug2_id = m2.id
           WHERE ddi.drug1_id = ?
           UNION
           SELECT ddi.*, m1.generic_name as interacting_drug_name
           FROM drug_drug_interactions ddi
           JOIN medications m1 ON ddi.drug1_id = m1.id
           WHERE ddi.drug2_id = ?""",
        (med_id, med_id),
    )
    drug_interactions = await cursor.fetchall()

    # Drug–food interactions
    cursor = await db.execute(
        """SELECT dfi.*, f.name as food_name
           FROM drug_food_interactions dfi
           LEFT JOIN foods f ON dfi.food_id = f.id
           WHERE dfi.medication_id = ?""",
        (med_id,),
    )
    food_interactions = await cursor.fetchall()

    # Drug–beverage interactions
    cursor = await db.execute(
        "SELECT * FROM drug_beverage_interactions WHERE medication_id = ?",
        (med_id,),
    )
    bev_interactions = await cursor.fetchall()

    return {
        "medication": med,
        "drug_drug_interactions": drug_interactions,
        "drug_food_interactions": food_interactions,
        "drug_beverage_interactions": bev_interactions,
    }


# ---------------------------------------------------------------------------
# User medication schedules
# ---------------------------------------------------------------------------

async def get_user_schedules(db: aiosqlite.Connection, user_id: int) -> list:
    cursor = await db.execute(
        """SELECT ms.*, m.generic_name, m.brand_name, m.category
           FROM medication_schedules ms
           JOIN medications m ON ms.medication_id = m.id
           WHERE ms.user_id = ? AND ms.is_active = TRUE
           ORDER BY ms.start_date""",
        (user_id,),
    )
    return await cursor.fetchall()


async def create_schedule(db: aiosqlite.Connection, user_id: int, data: dict) -> dict:
    now = datetime.now(timezone.utc).isoformat()
    cursor = await db.execute(
        """INSERT INTO medication_schedules
           (user_id, medication_id, schedule_type, times_per_day, scheduled_times,
            dose_amount, meal_relation, start_date, end_date, is_active,
            reminder_enabled, reminder_minutes_before, notes, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, TRUE, ?, ?, ?, ?)""",
        (
            user_id,
            data["medication_id"],
            data.get("schedule_type", "daily"),
            data.get("times_per_day", 1),
            data.get("scheduled_times"),
            data.get("dose_amount"),
            data.get("meal_relation", "with_meal"),
            data["start_date"],
            data.get("end_date"),
            data.get("reminder_enabled", True),
            data.get("reminder_minutes_before", 15),
            data.get("notes"),
            now,
        ),
    )
    await db.commit()
    return {"schedule_id": cursor.lastrowid, "status": "created"}


async def deactivate_schedule(db: aiosqlite.Connection, user_id: int, schedule_id: int) -> bool:
    result = await db.execute(
        "UPDATE medication_schedules SET is_active = FALSE WHERE id = ? AND user_id = ?",
        (schedule_id, user_id),
    )
    await db.commit()
    return result.rowcount > 0


# ---------------------------------------------------------------------------
# Adherence logging
# ---------------------------------------------------------------------------

async def log_adherence(db: aiosqlite.Connection, user_id: int, data: dict) -> dict:
    now = datetime.now(timezone.utc).isoformat()
    cursor = await db.execute(
        """INSERT INTO adherence_logs
           (user_id, medication_id, schedule_id, scheduled_at, taken_at, status,
            dose_taken, skip_reason, side_effects, notes, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (
            user_id,
            data["medication_id"],
            data.get("schedule_id"),
            data.get("scheduled_at"),
            data.get("taken_at", now),
            data.get("status", "taken"),
            data.get("dose_taken"),
            data.get("skip_reason"),
            data.get("side_effects"),
            data.get("notes"),
            now,
        ),
    )
    await db.commit()

    # Award XP for taking medication (status = taken)
    if data.get("status", "taken") == "taken":
        await db.execute(
            "UPDATE avatar_stats SET current_xp = current_xp + 5 WHERE user_id = ?",
            (user_id,),
        )
        await db.commit()

    return {"log_id": cursor.lastrowid, "status": data.get("status", "taken")}


async def get_adherence_history(db: aiosqlite.Connection, user_id: int, days: int = 7) -> dict:
    cursor = await db.execute(
        """SELECT al.*, m.generic_name, m.brand_name
           FROM adherence_logs al
           JOIN medications m ON al.medication_id = m.id
           WHERE al.user_id = ? AND al.created_at >= datetime('now', ? || ' days')
           ORDER BY al.created_at DESC""",
        (user_id, f"-{days}"),
    )
    logs = await cursor.fetchall()

    # Adherence rate
    cursor = await db.execute(
        """SELECT
             COUNT(*) as total,
             SUM(CASE WHEN status = 'taken' THEN 1 ELSE 0 END) as taken
           FROM adherence_logs
           WHERE user_id = ? AND created_at >= datetime('now', ? || ' days')""",
        (user_id, f"-{days}"),
    )
    stats = await cursor.fetchone()
    total = stats["total"] or 0
    taken = stats["taken"] or 0
    rate = round((taken / total * 100), 1) if total > 0 else 0.0

    return {"logs": logs, "adherence_rate_pct": rate, "period_days": days}


# ---------------------------------------------------------------------------
# Pharmacy orders
# ---------------------------------------------------------------------------

async def get_user_orders(db: aiosqlite.Connection, user_id: int, limit: int = 20) -> list:
    cursor = await db.execute(
        """SELECT po.*
           FROM pharmacy_orders po
           WHERE po.user_id = ?
           ORDER BY po.id DESC
           LIMIT ?""",
        (user_id, limit),
    )
    return await cursor.fetchall()
