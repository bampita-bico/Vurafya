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
    return {"user_id": user_id, "eligible_for_0pct_fees": eligible, "status": "registered"}


async def get_vulnerable_profile(db: aiosqlite.Connection, user_id: int) -> dict | None:
    cursor = await db.execute(
        "SELECT * FROM vulnerable_population_registry WHERE user_id = ?", (user_id,)
    )
    return await cursor.fetchone()


async def is_eligible_for_waiver(db: aiosqlite.Connection, user_id: int) -> bool:
    cursor = await db.execute(
        "SELECT eligible_for_0pct_fees FROM vulnerable_population_registry WHERE user_id = ? AND is_verified = 1",
        (user_id,),
    )
    row = await cursor.fetchone()
    return bool(row and row["eligible_for_0pct_fees"])


# ---------------------------------------------------------------------------
# Social good impact logging
# ---------------------------------------------------------------------------

async def log_social_good_transaction(db: aiosqlite.Connection, data: dict) -> dict:
    now = _now()
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    month = datetime.now(timezone.utc).strftime("%Y-%m-01")

    cursor = await db.execute(
        """INSERT INTO social_good_impact_log
           (transaction_id, transaction_type, user_id, user_category,
            transaction_value_ugx, fee_waived_ugx, fee_waived_pct,
            payment_method, used_barter, used_labor, used_afya_points, had_zero_fiat,
            impact_type, health_service_type,
            ckd_related, diabetes_related, hypertension_related,
            country_code, district, is_rural,
            is_success_story, impact_date, month, created_at)
           VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,0,?,?,?)""",
        (
            data.get("transaction_id"),
            data.get("transaction_type", "general"),
            data.get("user_id"),
            data.get("user_category", "low_income"),
            data.get("value_ugx", 0),
            data.get("fee_waived_ugx", 0),
            data.get("fee_waived_pct", 0),
            data.get("payment_method", "afya_points"),
            data.get("used_barter", False),
            data.get("used_labor", False),
            data.get("used_afya_points", False),
            data.get("had_zero_fiat", False),
            data.get("impact_type", "healthcare"),
            data.get("health_service_type", "general"),
            data.get("ckd_related", False),
            data.get("diabetes_related", False),
            data.get("hypertension_related", False),
            data.get("country_code", "UG"),
            data.get("district"),
            data.get("is_rural", False),
            today, month, now,
        ),
    )

    # Update lifetime value on vulnerable registry
    if data.get("user_id"):
        await db.execute(
            """UPDATE vulnerable_population_registry
               SET lifetime_social_good_value_ugx = lifetime_social_good_value_ugx + ?,
                   monthly_transactions_used = monthly_transactions_used + 1,
                   updated_at = ?
               WHERE user_id = ?""",
            (data.get("value_ugx", 0), now, data["user_id"]),
        )

    await db.commit()
    return {"impact_log_id": cursor.lastrowid}


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


# ---------------------------------------------------------------------------
# Fee waiver logging
# ---------------------------------------------------------------------------

async def log_fee_waiver(db: aiosqlite.Connection, data: dict) -> dict:
    now = _now()
    cursor = await db.execute(
        """INSERT INTO fee_waiver_log
           (transaction_id, transaction_type, user_id,
            original_fee_ugx, waived_fee_ugx, waiver_reason,
            is_social_good, social_good_category, created_at)
           VALUES (?,?,?,?,?,?,1,?,?)""",
        (
            data.get("transaction_id"),
            data.get("transaction_type", "general"),
            data.get("user_id"),
            data.get("original_fee_ugx", 0),
            data.get("waived_fee_ugx", 0),
            data.get("waiver_reason", "vulnerable_population"),
            data.get("social_good_category", "general"),
            now,
        ),
    )
    await db.commit()
    return {"waiver_log_id": cursor.lastrowid}
