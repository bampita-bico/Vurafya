import aiosqlite
import json
from datetime import datetime, timezone


def _now():
    return datetime.now(timezone.utc).isoformat()


# ---------------------------------------------------------------------------
# Vulnerable population registry
# ---------------------------------------------------------------------------

async def register_vulnerable(db: aiosqlite.Connection, user_id: int, data: dict) -> dict:
    now = _now()
    cursor = await db.execute(
        "SELECT id FROM vulnerable_population_registry WHERE user_id = ?", (user_id,)
    )
    existing = await cursor.fetchone()

    eligible = any([
        data.get("is_elderly"), data.get("is_disabled"), data.get("is_child"),
        data.get("is_pregnant"), data.get("is_low_income"), data.get("is_orphan"),
        data.get("is_refugee"), data.get("is_ckd_patient"),
    ])

    if existing:
        await db.execute(
            """UPDATE vulnerable_population_registry SET
               is_elderly=?, is_disabled=?, is_child=?, is_pregnant=?,
               is_low_income=?, is_orphan=?, is_refugee=?, is_ckd_patient=?,
               verification_method=?, verification_documents=?,
               eligible_for_0pct_fees=?, updated_at=?
               WHERE user_id=?""",
            (
                data.get("is_elderly", False), data.get("is_disabled", False),
                data.get("is_child", False), data.get("is_pregnant", False),
                data.get("is_low_income", False), data.get("is_orphan", False),
                data.get("is_refugee", False), data.get("is_ckd_patient", False),
                data.get("verification_method", "self_declared"),
                json.dumps(data.get("documents", [])),
                eligible, now, user_id,
            ),
        )
    else:
        await db.execute(
            """INSERT INTO vulnerable_population_registry
               (user_id, is_elderly, is_disabled, is_child, is_pregnant,
                is_low_income, is_orphan, is_refugee, is_ckd_patient,
                is_verified, verification_method, verification_documents,
                eligible_for_0pct_fees, eligible_for_priority_matching,
                eligible_for_subsidized_transport,
                max_monthly_transactions, monthly_transactions_used,
                lifetime_social_good_value_ugx, registered_at, updated_at)
               VALUES (?,?,?,?,?,?,?,?,?,0,?,?,?,1,1,10,0,0.0,?,?)""",
            (
                user_id,
                data.get("is_elderly", False), data.get("is_disabled", False),
                data.get("is_child", False), data.get("is_pregnant", False),
                data.get("is_low_income", False), data.get("is_orphan", False),
                data.get("is_refugee", False), data.get("is_ckd_patient", False),
                data.get("verification_method", "self_declared"),
                json.dumps(data.get("documents", [])),
                eligible,
                now, now,
            ),
        )
    await db.commit()
    return {"user_id": user_id, "eligible_for_support": eligible, "status": "registered"}


async def get_vulnerable_profile(db: aiosqlite.Connection, user_id: int) -> dict | None:
    cursor = await db.execute(
        "SELECT * FROM vulnerable_population_registry WHERE user_id = ?", (user_id,)
    )
    return await cursor.fetchone()


async def get_social_good_summary(db: aiosqlite.Connection) -> dict:
    cursor = await db.execute("SELECT * FROM v_current_month_social_good LIMIT 1")
    row = await cursor.fetchone()
    return dict(row) if row else {}


async def get_social_good_goals(db: aiosqlite.Connection) -> list:
    cursor = await db.execute("SELECT * FROM social_good_goals ORDER BY id")
    return await cursor.fetchall()

async def get_impact_history(db: aiosqlite.Connection, user_id: int) -> list:
    cursor = await db.execute(
        """SELECT * FROM social_good_impact_log
           WHERE user_id = ?
           ORDER BY impact_date DESC LIMIT 50""",
        (user_id,),
    )
    return await cursor.fetchall()
