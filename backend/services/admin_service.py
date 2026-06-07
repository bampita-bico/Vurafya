import aiosqlite
from datetime import datetime, timezone


def _now():
    return datetime.now(timezone.utc).isoformat()


# ---------------------------------------------------------------------------
# Platform health summary
# ---------------------------------------------------------------------------

async def get_platform_summary(db: aiosqlite.Connection) -> dict:
    cursor = await db.execute("SELECT * FROM v_platform_health_summary LIMIT 1")
    row = await cursor.fetchone()
    return dict(row) if row else {}


# ---------------------------------------------------------------------------
# Revenue
# ---------------------------------------------------------------------------

async def get_daily_revenue(db: aiosqlite.Connection, days: int = 30) -> list:
    cursor = await db.execute(
        """SELECT * FROM v_daily_platform_revenue
           ORDER BY revenue_date DESC
           LIMIT ?""",
        (days,),
    )
    return await cursor.fetchall()


async def get_current_month_revenue(db: aiosqlite.Connection) -> dict:
    cursor = await db.execute("SELECT * FROM v_current_month_revenue LIMIT 1")
    row = await cursor.fetchone()
    return dict(row) if row else {}


async def get_revenue_vs_target(db: aiosqlite.Connection) -> list:
    cursor = await db.execute("SELECT * FROM v_revenue_vs_target ORDER BY target_period")
    return await cursor.fetchall()


async def get_top_revenue_countries(db: aiosqlite.Connection) -> list:
    cursor = await db.execute("SELECT * FROM v_top_revenue_countries_current_month")
    return await cursor.fetchall()


async def get_monthly_summaries(db: aiosqlite.Connection, months: int = 12) -> list:
    cursor = await db.execute(
        "SELECT * FROM monthly_revenue_summary ORDER BY month DESC LIMIT ?",
        (months,),
    )
    return await cursor.fetchall()


async def get_country_revenue(db: aiosqlite.Connection, month: str = None) -> list:
    if month:
        cursor = await db.execute(
            "SELECT * FROM country_revenue_summary WHERE month = ? ORDER BY total_revenue_ugx DESC",
            (month,),
        )
    else:
        cursor = await db.execute(
            "SELECT * FROM country_revenue_summary ORDER BY month DESC, total_revenue_ugx DESC LIMIT 60"
        )
    return await cursor.fetchall()


async def get_revenue_targets(db: aiosqlite.Connection) -> list:
    cursor = await db.execute("SELECT * FROM revenue_targets ORDER BY id")
    return await cursor.fetchall()


# ---------------------------------------------------------------------------
# Subscription analytics
# ---------------------------------------------------------------------------

async def get_subscription_analytics(db: aiosqlite.Connection) -> list:
    cursor = await db.execute("SELECT * FROM v_subscription_analytics")
    return await cursor.fetchall()


# ---------------------------------------------------------------------------
# Consultation revenue
# ---------------------------------------------------------------------------

async def get_consultation_revenue(db: aiosqlite.Connection) -> list:
    cursor = await db.execute("SELECT * FROM v_consultation_revenue_breakdown ORDER BY gross_revenue_ugx DESC")
    return await cursor.fetchall()


# ---------------------------------------------------------------------------
# Partner performance
# ---------------------------------------------------------------------------

async def get_partner_performance(db: aiosqlite.Connection) -> list:
    cursor = await db.execute("SELECT * FROM v_partner_performance_dashboard ORDER BY total_revenue_ugx DESC")
    return await cursor.fetchall()


# ---------------------------------------------------------------------------
# Fraud & compliance
# ---------------------------------------------------------------------------

async def get_fraud_rules(db: aiosqlite.Connection) -> list:
    cursor = await db.execute("SELECT * FROM fraud_detection_rules ORDER BY risk_score_weight DESC")
    return await cursor.fetchall()


async def get_fraud_alerts(db: aiosqlite.Connection, status: str = None, limit: int = 50) -> list:
    if status:
        cursor = await db.execute(
            """SELECT fda.*, u.username
               FROM fraud_detection_alerts fda
               LEFT JOIN users u ON fda.user_id = u.id
               WHERE fda.review_status = ?
               ORDER BY fda.detected_at DESC LIMIT ?""",
            (status, limit),
        )
    else:
        cursor = await db.execute(
            """SELECT fda.*, u.username
               FROM fraud_detection_alerts fda
               LEFT JOIN users u ON fda.user_id = u.id
               ORDER BY fda.detected_at DESC LIMIT ?""",
            (limit,),
        )
    return await cursor.fetchall()


async def resolve_fraud_alert(db: aiosqlite.Connection, alert_id: int, admin_id: int, data: dict) -> dict:
    now = _now()
    cursor = await db.execute(
        "SELECT id, user_id FROM fraud_detection_alerts WHERE id = ?", (alert_id,)
    )
    alert = await cursor.fetchone()
    if not alert:
        return {"error": "Alert not found"}

    await db.execute(
        """UPDATE fraud_detection_alerts
           SET review_status=?, review_notes=?, reviewed_by=?, reviewed_at=?,
               is_resolved=1, resolution_action=?, resolved_by=?, resolved_at=?
           WHERE id=?""",
        (
            data.get("review_status", "reviewed"),
            data.get("notes", ""),
            admin_id,
            now,
            data.get("resolution_action", "no_action"),
            admin_id,
            now,
            alert_id,
        ),
    )
    await db.commit()
    return {"alert_id": alert_id, "resolved": True}


async def get_high_risk_users(db: aiosqlite.Connection) -> list:
    cursor = await db.execute("SELECT * FROM v_high_risk_users ORDER BY overall_fraud_risk_score DESC")
    return await cursor.fetchall()


async def get_users_requiring_kyc(db: aiosqlite.Connection) -> list:
    cursor = await db.execute("SELECT * FROM v_users_requiring_kyc")
    return await cursor.fetchall()


# ---------------------------------------------------------------------------
# Social good overview
# ---------------------------------------------------------------------------

async def get_social_good_summary(db: aiosqlite.Connection) -> dict:
    cursor = await db.execute("SELECT * FROM v_current_month_social_good LIMIT 1")
    row = await cursor.fetchone()
    return dict(row) if row else {}


async def get_vulnerable_population_summary(db: aiosqlite.Connection) -> dict:
    cursor = await db.execute("SELECT * FROM v_vulnerable_population_summary LIMIT 1")
    row = await cursor.fetchone()
    return dict(row) if row else {}
