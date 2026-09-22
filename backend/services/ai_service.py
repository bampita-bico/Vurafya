import aiosqlite
import json
from datetime import datetime, timezone
from backend.services.engine_adapter import VurafyaAdapter
from backend.services.cdfd_bridge import classify_operating_state


def _now():
    return datetime.now(timezone.utc).isoformat()


# ---------------------------------------------------------------------------
# Recommendations (rule-based app layer using existing data)
# The ai_model_registry / ai_recommendations tables are empty — we generate
# recommendations from real health data and store results there.
# ---------------------------------------------------------------------------

async def get_recommendations(db: aiosqlite.Connection, user_id: int, category: str = None) -> list:
    q = """SELECT ar.*, art.type_name, art.category
           FROM ai_recommendations ar
           JOIN ai_recommendation_types art ON ar.recommendation_type_id = art.id
           WHERE ar.user_id = ? AND ar.is_active = 1"""
    params = [user_id]
    if category:
        q += " AND art.category = ?"
        params.append(category)
    q += " ORDER BY ar.priority_score DESC, ar.created_at DESC LIMIT 20"
    cursor = await db.execute(q, params)
    return await cursor.fetchall()


async def generate_recommendations(db: aiosqlite.Connection, user_id: int) -> dict:
    """Generate and store fresh AI recommendations for a user."""
    now = _now()
    recommendations = []

    # --- STEP 0: local Vurafya stability analysis (Runtime optional) ---
    try:
        adapter = VurafyaAdapter()
        state = await adapter.get_patient_state(user_id)
        if state.get("mean_psi") is not None:
            current_psi = float(state["mean_psi"])
            rec_logic = state.get("runtime_guidance") or classify_operating_state(
                current_psi,
                meta={"life_number": current_psi},
                domain="vurafya_local",
            )
            model_state = rec_logic["state"]
            severity = "info"
            if "critical" in model_state:
                severity = "critical"
            elif model_state not in {"balanced"}:
                severity = "warning"

            recommendations.append({
                "type": "engine_stability_review",
                "category": "stability",
                "title": f"Model State: {model_state.upper().replace('_', ' ')}",
                "message": rec_logic["reason"],
                "severity": severity,
                "action_data": json.dumps({
                    "psi_s": current_psi,
                    "runtime_actions": rec_logic["actions"],
                    "regime": model_state,
                    "components": {
                        "renal": float(state.get("renal_psi", 1.0)),
                        "cardio": float(state.get("cardio_psi", 1.0)),
                        "metabolic": float(state.get("metabolic_psi", 1.0)),
                    }
                }),
                "priority": 10 if "critical" in model_state else 7,
            })
    except Exception as e:
        print(f"Engine stability analysis failed for user {user_id}: {e}")

    # 1. Nutrition recommendations (now filtered by Engine flux/constraint logic)
    cursor = await db.execute(
        "SELECT * FROM health_rules WHERE is_active = 1 ORDER BY priority DESC"
    )
    rules = await cursor.fetchall()

    for rule in rules:
        sql = rule["condition_sql"]
        if not sql:
            continue
        safe_sql = sql.replace(":user_id", "?")
        try:
            c = await db.execute(safe_sql, (user_id,))
            if await c.fetchone():
                recommendations.append({
                    "type": rule["recommendation_type"],
                    "category": "nutrition",
                    "title": rule["rule_name"].replace("_", " ").title(),
                    "message": rule["recommendation_text"],
                    "severity": rule["severity"],
                    "action_data": json.dumps({
                        "suggested_foods": json.loads(rule["suggested_foods_json"] or "[]"),
                        "avoid_foods": json.loads(rule["foods_to_avoid_json"] or "[]"),
                        "nutrient_targets": json.loads(rule["nutrient_targets_json"] or "{}"),
                    }),
                    "priority": rule["priority"] or 5,
                })
        except Exception:
            continue

    # 2. Medication adherence recommendation
    cursor = await db.execute(
        """SELECT COUNT(*) as missed FROM adherence_logs
           WHERE user_id = ? AND taken = 0
             AND scheduled_at >= datetime('now', '-7 days')""",
        (user_id,),
    )
    row = await cursor.fetchone()
    missed = row["missed"] if row else 0
    if missed >= 3:
        recommendations.append({
            "type": "medication_reminder",
            "category": "medication",
            "title": "Medication Adherence Alert",
            "message": f"{missed} medication doses were logged as missed in the past 7 days. Review the schedule with the care team.",
            "severity": "warning" if missed < 7 else "critical",
            "action_data": json.dumps({"missed_doses": missed}),
            "priority": 9,
        })

    # 3. Biometric check recommendation
    cursor = await db.execute(
        """SELECT MAX(measurement_date) as last_bp FROM blood_pressure_logs WHERE user_id = ?""",
        (user_id,),
    )
    row = await cursor.fetchone()
    last_bp = row["last_bp"] if row else None
    if not last_bp:
        recommendations.append({
            "type": "biometric_reminder",
            "category": "monitoring",
            "title": "Track Your Blood Pressure",
            "message": "No blood pressure log is available yet. Add a reading to improve the model context.",
            "severity": "info",
            "action_data": json.dumps({}),
            "priority": 4,
        })

    # 4. Subscription upsell if on Free tier
    cursor = await db.execute(
        """SELECT COALESCE(sp.tier, 1) as tier
           FROM users u
           LEFT JOIN user_subscriptions us ON u.id = us.user_id AND us.status IN ('active','trial')
           LEFT JOIN subscription_plans sp ON us.plan_id = sp.id
           WHERE u.id = ?""",
        (user_id,),
    )
    row = await cursor.fetchone()
    tier = row["tier"] if row else 1
    if tier == 1 and len([r for r in recommendations if r["severity"] == "critical"]) > 0:
        recommendations.append({
            "type": "subscription_upsell",
            "category": "platform",
            "title": "Unlock Pro Health Monitoring",
            "message": "Advanced monitoring tools are available in Afya Pro, including expanded trends and clinician-facing summaries.",
            "severity": "info",
            "action_data": json.dumps({"target_tier": 3}),
            "priority": 6,
        })

    # Get or create recommendation type IDs
    type_map = {}
    for rec in recommendations:
        rtype = rec["type"]
        if rtype not in type_map:
            cursor = await db.execute(
                "SELECT id FROM ai_recommendation_types WHERE type_name = ?", (rtype,)
            )
            row = await cursor.fetchone()
            if not row:
                cursor = await db.execute(
                    """INSERT INTO ai_recommendation_types
                       (type_name, category, description, priority_weight, is_active, created_at)
                       VALUES (?,?,?,1.0,1,?)""",
                    (rtype, rec["category"], rec["title"], now),
                )
                type_map[rtype] = cursor.lastrowid
            else:
                type_map[rtype] = row["id"]

    # Deactivate old recommendations for user
    await db.execute(
        "UPDATE ai_recommendations SET is_active = 0 WHERE user_id = ?", (user_id,)
    )

    # Insert fresh recommendations
    stored_ids = []
    for rec in recommendations:
        type_id = type_map.get(rec["type"])
        if not type_id:
            continue
        cursor = await db.execute(
            """INSERT INTO ai_recommendations
               (user_id, recommendation_type_id, title, message, severity,
                action_type, action_data, priority_score, is_active, generated_at, created_at)
               VALUES (?,?,?,?,?,?,?,?,1,?,?)""",
            (
                user_id, type_id,
                rec["title"], rec["message"], rec["severity"],
                rec["type"], rec.get("action_data", "{}"),
                rec["priority"],
                now, now,
            ),
        )
        stored_ids.append(cursor.lastrowid)

    await db.commit()
    return {
        "user_id": user_id,
        "recommendations_generated": len(stored_ids),
        "critical": sum(1 for r in recommendations if r["severity"] == "critical"),
        "warnings": sum(1 for r in recommendations if r["severity"] == "warning"),
        "generated_at": now,
    }


async def dismiss_recommendation(db: aiosqlite.Connection, user_id: int, rec_id: int) -> dict:
    await db.execute(
        "UPDATE ai_recommendations SET is_active = 0 WHERE id = ? AND user_id = ?",
        (rec_id, user_id),
    )
    await db.commit()
    return {"dismissed": rec_id}
