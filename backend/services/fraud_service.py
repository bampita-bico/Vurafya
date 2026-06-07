import aiosqlite
import json
from datetime import datetime, timezone


def _now():
    return datetime.now(timezone.utc).isoformat()


# ---------------------------------------------------------------------------
# Fraud rule evaluation
# Runs the 8 defined rules against a transaction and raises alerts.
# ---------------------------------------------------------------------------

async def evaluate_transaction(db: aiosqlite.Connection, user_id: int, transaction_data: dict) -> dict:
    """Evaluate a transaction against all active fraud rules. Returns risk assessment."""
    now = _now()
    amount_ugx = transaction_data.get("amount_ugx", 0)
    tx_type = transaction_data.get("transaction_type", "general")
    tx_id = transaction_data.get("transaction_id")

    alerts_triggered = []
    total_risk = 0.0

    # Fetch active rules
    cursor = await db.execute(
        "SELECT * FROM fraud_detection_rules WHERE is_active = 1 ORDER BY risk_score_weight DESC"
    )
    rules = await cursor.fetchall()

    # Fetch user account age in days
    cursor = await db.execute(
        "SELECT julianday('now') - julianday(created_at) AS age_days FROM users WHERE id = ?",
        (user_id,),
    )
    user_row = await cursor.fetchone()
    account_age_days = user_row["age_days"] if user_row else 999

    for rule in rules:
        triggered = False
        rule_code = rule["rule_code"]
        weight = rule["risk_score_weight"]

        if rule_code == "new_user_large_tx":
            triggered = account_age_days < 7 and amount_ugx > 1_000_000

        elif rule_code == "rapid_succession":
            cursor = await db.execute(
                """SELECT COUNT(*) as cnt FROM unified_payment_ledger
                   WHERE payer_user_id = ?
                     AND initiated_at >= datetime('now', '-5 minutes')""",
                (user_id,),
            )
            row = await cursor.fetchone()
            triggered = (row["cnt"] or 0) >= 5

        elif rule_code == "round_number_structuring":
            # Multiple transactions just under a round threshold (e.g. 999,000)
            cursor = await db.execute(
                """SELECT COUNT(*) as cnt FROM unified_payment_ledger
                   WHERE payer_user_id = ?
                     AND total_amount_ugx BETWEEN 950000 AND 999999
                     AND initiated_at >= datetime('now', '-1 day')""",
                (user_id,),
            )
            row = await cursor.fetchone()
            triggered = (row["cnt"] or 0) >= 3

        elif rule_code == "self_trading":
            payee_id = transaction_data.get("payee_id")
            triggered = payee_id is not None and payee_id == user_id

        elif rule_code == "unusual_volume_spike":
            # Compare today's volume to 7-day average
            cursor = await db.execute(
                """SELECT
                       SUM(CASE WHEN date(initiated_at) = date('now') THEN total_amount_ugx ELSE 0 END) as today,
                       AVG(total_amount_ugx) as avg7
                   FROM unified_payment_ledger
                   WHERE payer_user_id = ?
                     AND initiated_at >= datetime('now', '-7 days')""",
                (user_id,),
            )
            row = await cursor.fetchone()
            today = row["today"] or 0
            avg7 = row["avg7"] or 1
            triggered = today > avg7 * 5 and today > 500_000

        # repeat_no_show, impossible_travel, fake_goods_pattern
        # — these require GPS/HR data; mark as not triggered for now
        else:
            triggered = False

        if triggered:
            total_risk += weight
            alerts_triggered.append({
                "rule_code": rule_code,
                "rule_name": rule["rule_name"],
                "weight": weight,
                "auto_action": rule["auto_action"],
            })

    total_risk = min(1.0, total_risk)

    if total_risk >= 0.3:
        risk_level = "critical" if total_risk >= 0.8 else ("high" if total_risk >= 0.6 else ("medium" if total_risk >= 0.3 else "low"))

        # Insert alert
        await db.execute(
            """INSERT INTO fraud_detection_alerts
               (alert_type, user_id, transaction_id, transaction_type,
                risk_score, risk_level, fraud_indicators, fraud_indicator_count,
                alert_description, requires_manual_review,
                review_status, is_resolved, detected_at, created_at)
               VALUES (?,?,?,?,?,?,?,?,?,?,
                       CASE WHEN ? >= 0.6 THEN 'pending' ELSE 'auto_cleared' END,
                       CASE WHEN ? < 0.3 THEN 1 ELSE 0 END,
                       ?,?)""",
            (
                "transaction_risk",
                user_id,
                tx_id,
                tx_type,
                round(total_risk, 4),
                risk_level,
                json.dumps(alerts_triggered),
                len(alerts_triggered),
                f"Risk score {round(total_risk, 2)} on {tx_type} transaction",
                total_risk >= 0.6,
                total_risk, total_risk,
                now, now,
            ),
        )

        # Update user fraud history
        await _upsert_fraud_history(db, user_id, total_risk, now)
        await db.commit()

    # Determine auto-action
    auto_action = None
    if alerts_triggered:
        # Take the most severe auto action
        action_priority = {"block_transaction": 4, "suspend_user": 3, "manual_review": 2, "require_otp": 1}
        actions = [a["auto_action"] for a in alerts_triggered if a["auto_action"]]
        if actions:
            auto_action = max(actions, key=lambda x: action_priority.get(x, 0))

    return {
        "user_id": user_id,
        "risk_score": round(total_risk, 4),
        "risk_level": "low" if total_risk < 0.3 else ("medium" if total_risk < 0.6 else ("high" if total_risk < 0.8 else "critical")),
        "alerts_triggered": len(alerts_triggered),
        "auto_action": auto_action,
        "blocked": auto_action == "block_transaction",
    }


async def _upsert_fraud_history(db: aiosqlite.Connection, user_id: int, risk_score: float, now: str):
    cursor = await db.execute("SELECT id FROM user_fraud_history WHERE user_id = ?", (user_id,))
    existing = await cursor.fetchone()
    if existing:
        await db.execute(
            """UPDATE user_fraud_history
               SET total_fraud_alerts = total_fraud_alerts + 1,
                   overall_fraud_risk_score = MAX(overall_fraud_risk_score, ?),
                   fraud_risk_level = CASE
                       WHEN MAX(overall_fraud_risk_score, ?) >= 0.8 THEN 'critical'
                       WHEN MAX(overall_fraud_risk_score, ?) >= 0.6 THEN 'high'
                       WHEN MAX(overall_fraud_risk_score, ?) >= 0.3 THEN 'medium'
                       ELSE 'low' END,
                   last_fraud_alert_at = ?,
                   updated_at = ?
               WHERE user_id = ?""",
            (risk_score, risk_score, risk_score, risk_score, now, now, user_id),
        )
    else:
        level = "critical" if risk_score >= 0.8 else ("high" if risk_score >= 0.6 else ("medium" if risk_score >= 0.3 else "low"))
        await db.execute(
            """INSERT INTO user_fraud_history
               (user_id, total_fraud_alerts, confirmed_fraud_incidents, false_positive_alerts,
                overall_fraud_risk_score, fraud_risk_level,
                is_permanently_banned, is_temporarily_suspended,
                last_fraud_alert_at, created_at, updated_at)
               VALUES (?,1,0,0,?,?,0,0,?,?,?)""",
            (user_id, risk_score, level, now, now, now),
        )


async def get_user_fraud_profile(db: aiosqlite.Connection, user_id: int) -> dict | None:
    cursor = await db.execute("SELECT * FROM user_fraud_history WHERE user_id = ?", (user_id,))
    return await cursor.fetchone()
