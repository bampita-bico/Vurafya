import aiosqlite
from datetime import datetime, timezone, date


async def get_avatar(db: aiosqlite.Connection, user_id: int) -> dict | None:
    cursor = await db.execute(
        """SELECT avs.*, gcc.class_name, gcc.description as class_description, gcc.focus_area
           FROM avatar_stats avs
           LEFT JOIN game_character_classes gcc ON avs.class_id = gcc.id
           WHERE avs.user_id = ?""",
        (user_id,),
    )
    return await cursor.fetchone()


async def get_character_classes(db: aiosqlite.Connection) -> list:
    cursor = await db.execute(
        "SELECT * FROM game_character_classes ORDER BY id"
    )
    return await cursor.fetchall()


async def choose_class(db: aiosqlite.Connection, user_id: int, class_id: int) -> dict:
    # Check class exists
    cursor = await db.execute("SELECT * FROM game_character_classes WHERE id = ?", (class_id,))
    cls = await cursor.fetchone()
    if not cls:
        return {"error": "Class not found"}

    # Check if already chosen
    cursor = await db.execute("SELECT class_id FROM avatar_stats WHERE user_id = ?", (user_id,))
    avatar = await cursor.fetchone()
    if avatar and avatar["class_id"]:
        return {"error": "Class already chosen"}

    await db.execute("UPDATE avatar_stats SET class_id = ? WHERE user_id = ?", (class_id, user_id))
    await db.commit()
    return {"class_name": cls["class_name"], "focus_area": cls["focus_area"]}


async def get_available_quests(db: aiosqlite.Connection, user_id: int, user_tier: int) -> list:
    cursor = await db.execute("SELECT level FROM avatar_stats WHERE user_id = ?", (user_id,))
    avatar = await cursor.fetchone()
    user_level = avatar["level"] if avatar else 1

    cursor = await db.execute(
        """SELECT gq.*,
                  uqp.is_completed as user_completed, uqp.current_value
           FROM game_quests gq
           LEFT JOIN user_quest_progress uqp ON gq.id = uqp.quest_id AND uqp.user_id = ?
           WHERE gq.is_active = TRUE
             AND gq.min_level_required <= ?
             AND COALESCE(gq.requires_subscription_tier, 1) <= ?
           ORDER BY gq.min_level_required, gq.name""",
        (user_id, user_level, user_tier),
    )
    return await cursor.fetchall()


async def get_quest_detail(db: aiosqlite.Connection, quest_id: int) -> dict | None:
    cursor = await db.execute("SELECT * FROM game_quests WHERE id = ?", (quest_id,))
    quest = await cursor.fetchone()
    if not quest:
        return None

    cursor = await db.execute(
        "SELECT * FROM quest_objectives WHERE quest_id = ? ORDER BY sequence_order",
        (quest_id,),
    )
    objectives = await cursor.fetchall()

    return {"quest": quest, "objectives": objectives}


async def get_achievements(db: aiosqlite.Connection, user_id: int, user_tier: int) -> list:
    cursor = await db.execute(
        """SELECT a.*,
                  ua.unlocked_at,
                  CASE WHEN ua.id IS NOT NULL THEN TRUE ELSE FALSE END as unlocked
           FROM achievements a
           LEFT JOIN user_achievements ua ON a.id = ua.achievement_id AND ua.user_id = ?
           WHERE COALESCE(a.requires_subscription_tier, 1) <= ?
           ORDER BY a.category, a.name""",
        (user_id, user_tier),
    )
    return await cursor.fetchall()


async def claim_daily_login(db: aiosqlite.Connection, user_id: int) -> dict:
    today = date.today().isoformat()

    # Check if already claimed today
    cursor = await db.execute(
        "SELECT id FROM user_daily_logins WHERE user_id = ? AND login_date = ?",
        (user_id, today),
    )
    if await cursor.fetchone():
        return {"already_claimed": True, "date": today}

    # Get current streak
    cursor = await db.execute(
        "SELECT current_streak FROM avatar_stats WHERE user_id = ?", (user_id,)
    )
    avatar = await cursor.fetchone()
    current_streak = (avatar["current_streak"] or 0) if avatar else 0

    # Check if yesterday was claimed (streak continuity)
    cursor = await db.execute(
        "SELECT id FROM user_daily_logins WHERE user_id = ? AND login_date = date(?, '-1 day')",
        (user_id, today),
    )
    yesterday = await cursor.fetchone()
    new_streak = (current_streak + 1) if yesterday else 1

    # Get today's calendar reward (cycle through 30 days)
    day_in_cycle = ((new_streak - 1) % 30) + 1
    cursor = await db.execute(
        "SELECT * FROM daily_login_calendar WHERE day_number = ?", (day_in_cycle,)
    )
    calendar = await cursor.fetchone()

    xp_reward = 10
    ap_reward = 0
    if calendar:
        reward_type = calendar.get("reward_type", "xp")
        reward_value = calendar.get("reward_value", 10) or 10
        if reward_type == "xp":
            xp_reward = reward_value
        elif reward_type == "ap":
            ap_reward = reward_value
        else:
            xp_reward = reward_value

    # Record login
    await db.execute(
        "INSERT INTO user_daily_logins (user_id, login_date, day_in_cycle, reward_claimed) VALUES (?, ?, ?, TRUE)",
        (user_id, today, day_in_cycle),
    )

    # Update streak and XP
    await db.execute(
        """UPDATE avatar_stats SET current_streak = ?,
           current_xp = current_xp + ?,
           afya_points_balance = afya_points_balance + ?
           WHERE user_id = ?""",
        (new_streak, xp_reward, ap_reward, user_id),
    )

    # Check for level up
    cursor = await db.execute(
        "SELECT current_xp, xp_to_next_level, level FROM avatar_stats WHERE user_id = ?",
        (user_id,),
    )
    stats = await cursor.fetchone()
    leveled_up = False
    if stats and stats["current_xp"] >= stats["xp_to_next_level"]:
        new_level = stats["level"] + 1
        cursor = await db.execute(
            "SELECT xp_required FROM character_progression WHERE level = ?", (new_level,)
        )
        next_prog = await cursor.fetchone()
        new_xp_target = next_prog["xp_required"] if next_prog else stats["xp_to_next_level"] * 2

        await db.execute(
            "UPDATE avatar_stats SET level = ?, xp_to_next_level = ? WHERE user_id = ?",
            (new_level, new_xp_target, user_id),
        )
        leveled_up = True

    # Check streak milestones
    milestone_reward = None
    cursor = await db.execute(
        "SELECT * FROM login_streak_milestones WHERE streak_days = ?", (new_streak,)
    )
    milestone = await cursor.fetchone()
    if milestone:
        reward_type = milestone.get("reward_type", "xp")
        reward_value = milestone.get("reward_value", 0) or 0
        if reward_value:
            if reward_type == "ap":
                await db.execute(
                    "UPDATE avatar_stats SET afya_points_balance = afya_points_balance + ? WHERE user_id = ?",
                    (reward_value, user_id),
                )
            else:
                await db.execute(
                    "UPDATE avatar_stats SET current_xp = current_xp + ? WHERE user_id = ?",
                    (reward_value, user_id),
                )
        milestone_reward = milestone

    await db.commit()

    return {
        "already_claimed": False,
        "date": today,
        "streak": new_streak,
        "day_in_cycle": day_in_cycle,
        "xp_earned": xp_reward,
        "ap_earned": ap_reward,
        "leveled_up": leveled_up,
        "milestone": milestone_reward,
    }


async def get_streaks(db: aiosqlite.Connection, user_id: int) -> dict:
    cursor = await db.execute(
        "SELECT current_streak, level, current_xp, xp_to_next_level, afya_points_balance FROM avatar_stats WHERE user_id = ?",
        (user_id,),
    )
    stats = await cursor.fetchone()

    cursor = await db.execute(
        "SELECT COUNT(*) as total_logins FROM user_daily_logins WHERE user_id = ?",
        (user_id,),
    )
    logins = await cursor.fetchone()

    return {
        "current_streak": stats["current_streak"] if stats else 0,
        "total_logins": logins["total_logins"] if logins else 0,
        "level": stats["level"] if stats else 1,
        "current_xp": stats["current_xp"] if stats else 0,
        "xp_to_next_level": stats["xp_to_next_level"] if stats else 100,
        "afya_points": stats["afya_points_balance"] if stats else 0,
    }
