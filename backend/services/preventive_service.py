import aiosqlite
import json
from datetime import datetime, timezone


def _now():
    return datetime.now(timezone.utc).isoformat()


# ---------------------------------------------------------------------------
# Health rules engine
# Evaluates all active health_rules against a user's current lab data.
# ---------------------------------------------------------------------------

async def evaluate_health_rules(db: aiosqlite.Connection, user_id: int) -> list:
    """Run all active health rules for a user. Returns triggered recommendations."""
    cursor = await db.execute(
        "SELECT * FROM health_rules WHERE is_active IN (1, 'TRUE', 'true', '1') ORDER BY priority DESC"
    )
    rules = await cursor.fetchall()
    triggered = []

    for rule in rules:
        sql = rule["condition_sql"]
        if not sql or not sql.strip():
            continue
        # Replace :user_id placeholder
        safe_sql = sql.replace(":user_id", "?")
        try:
            c = await db.execute(safe_sql, (user_id,))
            row = await c.fetchone()
            if row:
                suggested_foods = json.loads(rule["suggested_foods_json"]) if rule["suggested_foods_json"] else []
                avoid_foods = json.loads(rule["foods_to_avoid_json"]) if rule["foods_to_avoid_json"] else []
                nutrient_targets = json.loads(rule["nutrient_targets_json"]) if rule["nutrient_targets_json"] else {}

                triggered.append({
                    "rule_id": rule["id"],
                    "rule_name": rule["rule_name"],
                    "rule_category": rule["rule_category"],
                    "recommendation_type": rule["recommendation_type"],
                    "severity": rule["severity"],
                    "recommendation_text": rule["recommendation_text"],
                    "suggested_food_ids": suggested_foods,
                    "avoid_food_ids": avoid_foods,
                    "nutrient_targets": nutrient_targets,
                })
        except Exception:
            continue

    return triggered


async def get_health_rules(db: aiosqlite.Connection, category: str = None) -> list:
    if category:
        cursor = await db.execute(
            "SELECT * FROM health_rules WHERE is_active IN (1, 'TRUE', 'true', '1') AND rule_category = ? ORDER BY priority DESC",
            (category,),
        )
    else:
        cursor = await db.execute(
            "SELECT * FROM health_rules WHERE is_active IN (1, 'TRUE', 'true', '1') ORDER BY priority DESC"
        )
    return await cursor.fetchall()


# ---------------------------------------------------------------------------
# Risk prediction
# ---------------------------------------------------------------------------

async def get_risk_logs(db: aiosqlite.Connection, user_id: int) -> list:
    cursor = await db.execute(
        "SELECT * FROM risk_prediction_logs WHERE user_id = ? ORDER BY predicted_at DESC LIMIT 20",
        (user_id,),
    )
    return await cursor.fetchall()


async def log_risk_assessment(db: aiosqlite.Connection, user_id: int, data: dict) -> dict:
    now = _now()
    cursor = await db.execute(
        """INSERT INTO risk_prediction_logs
           (user_id, condition_name, risk_score, risk_category,
            risk_factors, protective_factors, recommendations,
            model_version, confidence_score, predicted_at)
           VALUES (?,?,?,?,?,?,?,'rules_engine_v1',?,?)""",
        (
            user_id,
            data["condition_name"],
            data["risk_score"],
            data["risk_category"],
            json.dumps(data.get("risk_factors", [])),
            json.dumps(data.get("protective_factors", [])),
            json.dumps(data.get("recommendations", [])),
            data.get("confidence_score", 0.8),
            now,
        ),
    )
    await db.commit()
    return {"log_id": cursor.lastrowid}


# ---------------------------------------------------------------------------
# User conditions
# ---------------------------------------------------------------------------

async def get_user_conditions(db: aiosqlite.Connection, user_id: int) -> list:
    cursor = await db.execute(
        """SELECT uc.*, mc.condition_name, mc.icd_10_code, mc.category,
                  mc.is_chronic, mc.requires_specialist
           FROM user_conditions uc
           JOIN medical_conditions mc ON uc.condition_id = mc.id
           WHERE uc.user_id = ?
           ORDER BY uc.is_primary DESC, uc.created_at""",
        (user_id,),
    )
    return await cursor.fetchall()


async def get_all_conditions(db: aiosqlite.Connection) -> list:
    cursor = await db.execute(
        "SELECT * FROM medical_conditions ORDER BY category, condition_name"
    )
    return await cursor.fetchall()


# ---------------------------------------------------------------------------
# Condition-specific nutrition rules
# ---------------------------------------------------------------------------

async def get_condition_nutrition_rules(db: aiosqlite.Connection, condition_id: int) -> list:
    cursor = await db.execute(
        """SELECT cnr.*, mc.condition_name
           FROM condition_nutrition_rules cnr
           JOIN medical_conditions mc ON cnr.condition_id = mc.id
           WHERE cnr.condition_id = ? AND cnr.is_active = 1
           ORDER BY cnr.priority DESC""",
        (condition_id,),
    )
    return await cursor.fetchall()


async def get_user_nutrition_rules(db: aiosqlite.Connection, user_id: int) -> list:
    """Get all nutrition rules for all of a user's declared conditions."""
    cursor = await db.execute(
        """SELECT cnr.*, mc.condition_name, uc.severity as user_severity
           FROM condition_nutrition_rules cnr
           JOIN user_conditions uc ON cnr.condition_id = uc.condition_id
           JOIN medical_conditions mc ON cnr.condition_id = mc.id
           WHERE uc.user_id = ? AND cnr.is_active = 1
           ORDER BY cnr.priority DESC""",
        (user_id,),
    )
    return await cursor.fetchall()


# ---------------------------------------------------------------------------
# Nutrient targets (personalised RDA)
# ---------------------------------------------------------------------------

async def get_nutrient_targets(db: aiosqlite.Connection, user_id: int) -> list:
    cursor = await db.execute(
        """SELECT nt.*, n.nutrient_name, n.unit
           FROM nutrient_targets nt
           JOIN nutrients n ON nt.nutrient_id = n.id
           WHERE nt.user_id = ?""",
        (user_id,),
    )
    return await cursor.fetchall()


async def upsert_nutrient_target(db: aiosqlite.Connection, user_id: int, data: dict) -> dict:
    now = _now()
    cursor = await db.execute(
        "SELECT id FROM nutrient_targets WHERE user_id = ? AND nutrient_id = ?",
        (user_id, data["nutrient_id"]),
    )
    existing = await cursor.fetchone()
    if existing:
        await db.execute(
            "UPDATE nutrient_targets SET target_value = ? WHERE user_id = ? AND nutrient_id = ?",
            (data["target_value"], user_id, data["nutrient_id"]),
        )
    else:
        await db.execute(
            "INSERT INTO nutrient_targets (user_id, nutrient_id, target_value, created_at) VALUES (?,?,?,?)",
            (user_id, data["nutrient_id"], data["target_value"], now),
        )
    await db.commit()
    return {"user_id": user_id, "nutrient_id": data["nutrient_id"], "target_value": data["target_value"]}


# ---------------------------------------------------------------------------
# CKD smart views
# ---------------------------------------------------------------------------

async def get_ckd_status(db: aiosqlite.Connection, user_id: int) -> dict | None:
    cursor = await db.execute(
        "SELECT * FROM v_user_ckd_lab_status WHERE user_id = ?", (user_id,)
    )
    row = await cursor.fetchone()
    return dict(row) if row else None


async def get_dynamic_food_recommendations(db: aiosqlite.Connection, user_id: int) -> list:
    cursor = await db.execute(
        "SELECT * FROM v_dynamic_food_recommendations WHERE user_id = ? LIMIT 50",
        (user_id,),
    )
    return await cursor.fetchall()


# ---------------------------------------------------------------------------
# Full health snapshot (combines rules + conditions + CKD)
# ---------------------------------------------------------------------------

async def get_health_snapshot(db: aiosqlite.Connection, user_id: int) -> dict:
    triggered_rules = await evaluate_health_rules(db, user_id)
    conditions = await get_user_conditions(db, user_id)
    nutrition_rules = await get_user_nutrition_rules(db, user_id)
    ckd = await get_ckd_status(db, user_id)
    risk_logs = await get_risk_logs(db, user_id)

    critical_count = sum(1 for r in triggered_rules if r["severity"] == "critical")
    warning_count = sum(1 for r in triggered_rules if r["severity"] == "warning")

    return {
        "user_id": user_id,
        "health_status": "critical" if critical_count > 0 else ("warning" if warning_count > 0 else "good"),
        "critical_alerts": critical_count,
        "warnings": warning_count,
        "triggered_rules": triggered_rules,
        "conditions": conditions,
        "nutrition_rules": nutrition_rules,
        "ckd_status": ckd,
        "recent_risk_assessments": risk_logs[:5],
    }
