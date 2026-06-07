import aiosqlite
from datetime import datetime, timezone


async def get_complete_profile(db: aiosqlite.Connection, user_id: int) -> dict | None:
    cursor = await db.execute(
        """SELECT u.id, u.email, u.username, u.has_completed_health_declaration,
                  u.primary_condition_id, u.created_at, u.last_login,
                  sp.plan_name as subscription_plan, sp.tier as subscription_tier,
                  us.status as subscription_status,
                  mc.condition_name as primary_condition,
                  avs.level, avs.current_xp, avs.current_streak, avs.afya_points_balance
           FROM users u
           LEFT JOIN user_subscriptions us ON u.id = us.user_id AND us.status IN ('active', 'trial')
           LEFT JOIN subscription_plans sp ON us.plan_id = sp.id
           LEFT JOIN medical_conditions mc ON u.primary_condition_id = mc.id
           LEFT JOIN avatar_stats avs ON u.id = avs.user_id
           WHERE u.id = ?""",
        (user_id,),
    )
    return await cursor.fetchone()


async def update_profile(db: aiosqlite.Connection, user_id: int, data: dict) -> None:
    fields = []
    values = []
    allowed = ["age", "gender", "height_cm", "weight_kg", "activity_level", "health_goal", "country_code"]
    for key in allowed:
        if key in data and data[key] is not None:
            fields.append(f"{key} = ?")
            values.append(data[key])

    if not fields:
        return

    values.append(user_id)
    await db.execute(
        f"UPDATE user_Profiles SET {', '.join(fields)} WHERE user_id = ?",
        values,
    )
    await db.commit()


async def submit_health_declaration(
    db: aiosqlite.Connection, user_id: int, condition_id: int,
    stage: str | None, severity: str, declaration_source: str
) -> dict:
    now = datetime.now(timezone.utc).isoformat()

    # Get condition name
    cursor = await db.execute("SELECT condition_name FROM medical_conditions WHERE id = ?", (condition_id,))
    condition = await cursor.fetchone()
    if not condition:
        return {"error": "Condition not found"}

    # Deactivate previous primary conditions
    await db.execute(
        "UPDATE user_conditions SET is_primary = FALSE WHERE user_id = ? AND is_primary = TRUE",
        (user_id,),
    )

    # Insert new condition
    await db.execute(
        """INSERT INTO user_conditions (user_id, condition_id, stage, severity, is_primary, status,
           declaration_source, declared_at)
           VALUES (?, ?, ?, ?, TRUE, 'active', ?, ?)""",
        (user_id, condition_id, stage, severity, declaration_source, now),
    )

    # Update users table
    await db.execute(
        """UPDATE users SET has_completed_health_declaration = TRUE,
           health_declaration_date = ?, primary_condition_id = ?
           WHERE id = ?""",
        (now, condition_id, user_id),
    )

    # Auto-generate nutrient targets from templates
    cursor = await db.execute(
        """SELECT nutrient_name, target_min, target_max, unit
           FROM condition_nutrient_templates
           WHERE condition = ?""",
        (condition["condition_name"],),
    )
    templates = await cursor.fetchall()

    for t in templates:
        # Look up nutrient ID by name
        cursor = await db.execute(
            "SELECT id FROM nutrients WHERE name = ?", (t["nutrient_name"],)
        )
        nutrient = await cursor.fetchone()
        if nutrient:
            target_value = t["target_max"] or t["target_min"] or 0
            await db.execute(
                """INSERT OR REPLACE INTO nutrient_targets
                   (user_id, nutrient_id, target_value, created_at)
                   VALUES (?, ?, ?, ?)""",
                (user_id, nutrient["id"], target_value, now),
            )

    await db.commit()
    return {"condition": condition["condition_name"], "stage": stage, "targets_generated": len(templates)}


async def get_user_conditions(db: aiosqlite.Connection, user_id: int) -> list:
    cursor = await db.execute(
        """SELECT uc.*, mc.condition_name, mc.category, mc.description
           FROM user_conditions uc
           JOIN medical_conditions mc ON uc.condition_id = mc.id
           WHERE uc.user_id = ? AND uc.status = 'active'
           ORDER BY uc.is_primary DESC""",
        (user_id,),
    )
    return await cursor.fetchall()
