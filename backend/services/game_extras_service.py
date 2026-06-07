import aiosqlite
import json
from datetime import datetime, timezone


# ---------------------------------------------------------------------------
# Bosses
# ---------------------------------------------------------------------------

async def get_bosses(db: aiosqlite.Connection, user_id: int, user_tier: int) -> list:
    cursor = await db.execute(
        "SELECT level FROM avatar_stats WHERE user_id = ?", (user_id,)
    )
    avatar = await cursor.fetchone()
    user_level = avatar["level"] if avatar else 1

    cursor = await db.execute(
        """SELECT be.*,
                  ubp.status as user_status,
                  ubp.current_boss_hp,
                  ubp.total_defeats,
                  ubp.respawn_at
           FROM boss_encounters be
           LEFT JOIN user_boss_progress ubp ON be.id = ubp.boss_id AND ubp.user_id = ?
           WHERE be.is_active = TRUE
             AND be.min_level_required <= ?
             AND COALESCE(be.requires_subscription_tier, 1) <= ?
           ORDER BY be.difficulty_level""",
        (user_id, user_level, user_tier),
    )
    return await cursor.fetchall()


async def start_boss_fight(db: aiosqlite.Connection, user_id: int, boss_id: int, user_tier: int) -> dict:
    now = datetime.now(timezone.utc).isoformat()

    cursor = await db.execute("SELECT * FROM boss_encounters WHERE id = ? AND is_active = TRUE", (boss_id,))
    boss = await cursor.fetchone()
    if not boss:
        return {"error": "Boss not found"}

    if boss["requires_subscription_tier"] and user_tier < boss["requires_subscription_tier"]:
        return {"error": "Subscription upgrade required", "required_tier": boss["requires_subscription_tier"]}

    cursor = await db.execute(
        "SELECT level FROM avatar_stats WHERE user_id = ?", (user_id,)
    )
    avatar = await cursor.fetchone()
    if avatar and avatar["level"] < boss["min_level_required"]:
        return {"error": "Level too low", "required_level": boss["min_level_required"]}

    # Check if already in progress
    cursor = await db.execute(
        "SELECT * FROM user_boss_progress WHERE user_id = ? AND boss_id = ?", (user_id, boss_id)
    )
    existing = await cursor.fetchone()

    if existing:
        if existing["status"] == "in_progress":
            return {"error": "Fight already in progress"}
        if existing["status"] == "defeated" and existing["respawn_at"] and existing["respawn_at"] > now:
            return {"error": "Boss is respawning", "respawn_at": existing["respawn_at"]}

        await db.execute(
            """UPDATE user_boss_progress
               SET status = 'in_progress', current_boss_hp = ?,
                   damage_dealt = 0, attempt_number = attempt_number + 1,
                   started_at = ?, updated_at = ?
               WHERE user_id = ? AND boss_id = ?""",
            (boss["base_hp"], now, now, user_id, boss_id),
        )
    else:
        await db.execute(
            """INSERT INTO user_boss_progress
               (user_id, boss_id, status, current_boss_hp, damage_dealt,
                attempt_number, total_defeats, started_at, created_at, updated_at)
               VALUES (?, ?, 'in_progress', ?, 0, 1, 0, ?, ?, ?)""",
            (user_id, boss_id, boss["base_hp"], now, now, now),
        )

    await db.commit()
    return {
        "boss_id": boss_id,
        "boss_name": boss["boss_name"],
        "boss_hp": boss["base_hp"],
        "status": "fight_started",
    }


async def deal_boss_damage(db: aiosqlite.Connection, user_id: int, boss_id: int, damage: int) -> dict:
    now = datetime.now(timezone.utc).isoformat()

    cursor = await db.execute(
        "SELECT * FROM user_boss_progress WHERE user_id = ? AND boss_id = ? AND status = 'in_progress'",
        (user_id, boss_id),
    )
    progress = await cursor.fetchone()
    if not progress:
        return {"error": "No active fight with this boss"}

    cursor = await db.execute("SELECT * FROM boss_encounters WHERE id = ?", (boss_id,))
    boss = await cursor.fetchone()

    new_hp = max(0, progress["current_boss_hp"] - damage)
    new_damage = progress["damage_dealt"] + damage

    if new_hp == 0:
        # Boss defeated
        from datetime import timedelta
        import dateutil.parser as dp_mod
        xp = boss["xp_reward_base"]
        ap = boss["ap_reward_base"]

        await db.execute(
            """UPDATE user_boss_progress
               SET status = 'defeated', current_boss_hp = 0, damage_dealt = ?,
                   defeated_at = ?, total_defeats = total_defeats + 1,
                   respawn_at = datetime('now', '+' || ? || ' days'),
                   updated_at = ?
               WHERE user_id = ? AND boss_id = ?""",
            (new_damage, now, boss["respawn_days"], now, user_id, boss_id),
        )
        await db.execute(
            "UPDATE avatar_stats SET current_xp = current_xp + ?, afya_points_balance = afya_points_balance + ? WHERE user_id = ?",
            (xp, ap, user_id),
        )
        await db.commit()
        return {
            "boss_defeated": True,
            "remaining_hp": 0,
            "damage_dealt": new_damage,
            "xp_earned": xp,
            "ap_earned": ap,
            "respawn_days": boss["respawn_days"],
        }
    else:
        await db.execute(
            "UPDATE user_boss_progress SET current_boss_hp = ?, damage_dealt = ?, updated_at = ? WHERE user_id = ? AND boss_id = ?",
            (new_hp, new_damage, now, user_id, boss_id),
        )
        await db.commit()
        return {"boss_defeated": False, "remaining_hp": new_hp, "damage_dealt": new_damage}


# ---------------------------------------------------------------------------
# Guilds
# ---------------------------------------------------------------------------

async def get_guilds(db: aiosqlite.Connection, user_id: int, user_tier: int) -> list:
    if user_tier < 2:
        return []
    cursor = await db.execute(
        """SELECT g.*, u.username as leader_name
           FROM guilds g
           JOIN users u ON g.leader_id = u.id
           WHERE g.is_active = TRUE AND g.is_public = TRUE
           ORDER BY g.guild_level DESC, g.current_member_count DESC""",
    )
    return await cursor.fetchall()


async def create_guild(db: aiosqlite.Connection, user_id: int, user_tier: int, data: dict) -> dict:
    if user_tier < 3:
        return {"error": "Guild creation requires Pro subscription"}

    now = datetime.now(timezone.utc).isoformat()
    # Check not already in a guild
    cursor = await db.execute(
        "SELECT id FROM guild_members WHERE user_id = ? AND is_active = TRUE", (user_id,)
    )
    if await cursor.fetchone():
        return {"error": "Already a member of a guild"}

    cursor = await db.execute(
        """INSERT INTO guilds
           (guild_name, description, guild_tag, leader_id, guild_level, guild_xp,
            max_members, current_member_count, condition_focus, min_subscription_tier_join,
            min_subscription_tier_create, is_public, is_active, created_at, updated_at)
           VALUES (?, ?, ?, ?, 1, 0, 20, 1, ?, 2, 3, ?, TRUE, ?, ?)""",
        (
            data["guild_name"],
            data.get("description"),
            data.get("guild_tag"),
            user_id,
            data.get("condition_focus"),
            data.get("is_public", True),
            now, now,
        ),
    )
    guild_id = cursor.lastrowid

    # Leader joins as rank 5 (highest)
    cursor2 = await db.execute(
        "SELECT id FROM guild_ranks ORDER BY rank_level DESC LIMIT 1"
    )
    top_rank = await cursor2.fetchone()
    rank_id = top_rank["id"] if top_rank else 1

    await db.execute(
        """INSERT INTO guild_members (user_id, guild_id, rank_id, contribution_xp, joined_at, is_active)
           VALUES (?, ?, ?, 0, ?, TRUE)""",
        (user_id, guild_id, rank_id, now),
    )
    await db.commit()
    return {"guild_id": guild_id, "guild_name": data["guild_name"]}


async def join_guild(db: aiosqlite.Connection, user_id: int, user_tier: int, guild_id: int) -> dict:
    now = datetime.now(timezone.utc).isoformat()

    cursor = await db.execute(
        "SELECT * FROM guilds WHERE id = ? AND is_active = TRUE", (guild_id,)
    )
    guild = await cursor.fetchone()
    if not guild:
        return {"error": "Guild not found"}

    if user_tier < guild["min_subscription_tier_join"]:
        return {"error": "Subscription upgrade required to join this guild"}

    if guild["current_member_count"] >= guild["max_members"]:
        return {"error": "Guild is full"}

    cursor = await db.execute(
        "SELECT id FROM guild_members WHERE user_id = ? AND is_active = TRUE", (user_id,)
    )
    if await cursor.fetchone():
        return {"error": "Already in a guild"}

    # Lowest rank
    cursor = await db.execute("SELECT id FROM guild_ranks ORDER BY rank_level ASC LIMIT 1")
    lowest = await cursor.fetchone()
    rank_id = lowest["id"] if lowest else 1

    await db.execute(
        "INSERT INTO guild_members (user_id, guild_id, rank_id, contribution_xp, joined_at, is_active) VALUES (?, ?, ?, 0, ?, TRUE)",
        (user_id, guild_id, rank_id, now),
    )
    await db.execute(
        "UPDATE guilds SET current_member_count = current_member_count + 1 WHERE id = ?",
        (guild_id,),
    )
    await db.commit()
    return {"guild_id": guild_id, "guild_name": guild["guild_name"], "status": "joined"}


async def get_my_guild(db: aiosqlite.Connection, user_id: int) -> dict | None:
    cursor = await db.execute(
        """SELECT g.*, gm.rank_id, gm.contribution_xp, gr.rank_name
           FROM guild_members gm
           JOIN guilds g ON gm.guild_id = g.id
           JOIN guild_ranks gr ON gm.rank_id = gr.id
           WHERE gm.user_id = ? AND gm.is_active = TRUE""",
        (user_id,),
    )
    membership = await cursor.fetchone()
    if not membership:
        return None

    cursor = await db.execute(
        """SELECT gm.*, u.username, gr.rank_name
           FROM guild_members gm
           JOIN users u ON gm.user_id = u.id
           JOIN guild_ranks gr ON gm.rank_id = gr.id
           WHERE gm.guild_id = ? AND gm.is_active = TRUE
           ORDER BY gm.contribution_xp DESC""",
        (membership["id"],),
    )
    members = await cursor.fetchall()
    return {"guild": membership, "members": members}


# ---------------------------------------------------------------------------
# Crafting
# ---------------------------------------------------------------------------

async def get_crafting_recipes(db: aiosqlite.Connection, user_id: int, user_tier: int) -> list:
    cursor = await db.execute(
        "SELECT level FROM avatar_stats WHERE user_id = ?", (user_id,)
    )
    avatar = await cursor.fetchone()
    user_level = avatar["level"] if avatar else 1

    cursor = await db.execute(
        """SELECT cr.*, cqt.tier_name as max_quality
           FROM crafting_recipes cr
           LEFT JOIN crafting_quality_tiers cqt ON cqt.min_quality_score <= 100
           WHERE cr.is_active = TRUE
             AND COALESCE(cr.requires_subscription_tier, 1) <= ?
             AND cr.min_crafting_level <= ?
           GROUP BY cr.id
           ORDER BY cr.min_crafting_level, cr.recipe_name""",
        (user_tier, user_level),
    )
    return await cursor.fetchall()


async def craft_recipe(db: aiosqlite.Connection, user_id: int, user_tier: int, data: dict) -> dict:
    now = datetime.now(timezone.utc).isoformat()
    recipe_id = data["recipe_id"]
    food_ids = data.get("food_ids", [])

    cursor = await db.execute(
        "SELECT * FROM crafting_recipes WHERE id = ? AND is_active = TRUE", (recipe_id,)
    )
    recipe = await cursor.fetchone()
    if not recipe:
        return {"error": "Recipe not found"}

    if user_tier < (recipe["requires_subscription_tier"] or 1):
        return {"error": "Subscription upgrade required"}

    # Simple quality calculation: count of matching foods / required × 100
    quality_score = min(100.0, (len(food_ids) / max(recipe["required_food_count"], 1)) * 100)

    # Find quality tier
    cursor = await db.execute(
        """SELECT * FROM crafting_quality_tiers
           WHERE min_quality_score <= ? ORDER BY min_quality_score DESC LIMIT 1""",
        (quality_score,),
    )
    tier = await cursor.fetchone()
    quality_tier_id = tier["id"] if tier else 1
    xp = int(recipe["base_xp_reward"] * (quality_score / 100))
    ap = int(recipe["base_ap_reward"] * (quality_score / 100))

    cursor = await db.execute(
        """INSERT INTO user_crafting_inventory
           (user_id, recipe_id, crafted_name, quality_tier_id, quality_score,
            food_ids_used, xp_earned, ap_earned, effect_active, crafted_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, TRUE, ?)""",
        (
            user_id, recipe_id,
            f"{recipe['recipe_name']} ({tier['tier_name'] if tier else 'Basic'})",
            quality_tier_id, quality_score,
            json.dumps(food_ids),
            xp, ap, now,
        ),
    )
    craft_id = cursor.lastrowid

    await db.execute(
        "UPDATE avatar_stats SET current_xp = current_xp + ?, afya_points_balance = afya_points_balance + ? WHERE user_id = ?",
        (xp, ap, user_id),
    )
    await db.commit()

    return {
        "craft_id": craft_id,
        "recipe_name": recipe["recipe_name"],
        "quality_score": quality_score,
        "quality_tier": tier["tier_name"] if tier else "Basic",
        "xp_earned": xp,
        "ap_earned": ap,
    }


async def get_crafting_inventory(db: aiosqlite.Connection, user_id: int) -> list:
    cursor = await db.execute(
        """SELECT uci.*, cr.recipe_name, cr.effect_description, cr.effect_duration_hours,
                  cqt.tier_name as quality_tier_name, cqt.color_hex
           FROM user_crafting_inventory uci
           JOIN crafting_recipes cr ON uci.recipe_id = cr.id
           LEFT JOIN crafting_quality_tiers cqt ON uci.quality_tier_id = cqt.id
           WHERE uci.user_id = ?
           ORDER BY uci.crafted_at DESC""",
        (user_id,),
    )
    return await cursor.fetchall()


# ---------------------------------------------------------------------------
# Pets
# ---------------------------------------------------------------------------

async def get_pet_species(db: aiosqlite.Connection, user_tier: int) -> list:
    cursor = await db.execute(
        """SELECT * FROM pet_species
           WHERE is_active = TRUE AND COALESCE(requires_subscription_tier, 1) <= ?
           ORDER BY species_name""",
        (user_tier,),
    )
    return await cursor.fetchall()


async def get_my_pets(db: aiosqlite.Connection, user_id: int) -> list:
    cursor = await db.execute(
        """SELECT up.*, ps.species_name, ps.display_name, ps.native_region,
                  ps.special_ability_description, ps.icon
           FROM user_pets up
           JOIN pet_species ps ON up.species_id = ps.id
           WHERE up.user_id = ? AND up.is_active = TRUE
           ORDER BY up.is_favorite DESC, up.adopted_at""",
        (user_id,),
    )
    return await cursor.fetchall()


async def adopt_pet(db: aiosqlite.Connection, user_id: int, user_tier: int, data: dict) -> dict:
    now = datetime.now(timezone.utc).isoformat()
    species_id = data["species_id"]

    cursor = await db.execute(
        "SELECT * FROM pet_species WHERE id = ? AND is_active = TRUE", (species_id,)
    )
    species = await cursor.fetchone()
    if not species:
        return {"error": "Pet species not found"}

    if user_tier < (species["requires_subscription_tier"] or 1):
        return {"error": "Subscription upgrade required for this pet"}

    # Check pet count limit
    cursor = await db.execute(
        "SELECT COUNT(*) as count FROM user_pets WHERE user_id = ? AND is_active = TRUE",
        (user_id,),
    )
    count_row = await cursor.fetchone()
    max_pets = 1 if user_tier == 2 else (3 if user_tier == 3 else 0)
    if max_pets == 0:
        return {"error": "Pets require Plus or Pro subscription"}
    if count_row["count"] >= max_pets:
        return {"error": f"Maximum {max_pets} pet(s) allowed on your plan"}

    cursor = await db.execute(
        """INSERT INTO user_pets
           (user_id, species_id, pet_name, current_stage, happiness, health, hunger,
            is_active, is_favorite, total_care_actions, total_days_owned,
            adopted_at, updated_at)
           VALUES (?, ?, ?, 1, ?, ?, 50, TRUE, FALSE, 0, 0, ?, ?)""",
        (
            user_id, species_id,
            data.get("pet_name", species["display_name"]),
            species["base_happiness"], species["base_health"],
            now, now,
        ),
    )
    await db.commit()
    return {"pet_id": cursor.lastrowid, "species": species["display_name"], "status": "adopted"}


async def care_for_pet(db: aiosqlite.Connection, user_id: int, pet_id: int, action: str) -> dict:
    now = datetime.now(timezone.utc).isoformat()

    cursor = await db.execute(
        "SELECT * FROM user_pets WHERE id = ? AND user_id = ? AND is_active = TRUE",
        (pet_id, user_id),
    )
    pet = await cursor.fetchone()
    if not pet:
        return {"error": "Pet not found"}

    updates: dict = {"updated_at": now}
    xp_reward = 0

    if action == "feed":
        updates["hunger"] = min(100, (pet["hunger"] or 0) + 30)
        updates["happiness"] = min(100, (pet["happiness"] or 0) + 10)
        updates["last_fed_at"] = now
        xp_reward = 3
    elif action == "play":
        updates["happiness"] = min(100, (pet["happiness"] or 0) + 20)
        updates["hunger"] = max(0, (pet["hunger"] or 50) - 10)
        updates["last_played_at"] = now
        xp_reward = 5
    elif action == "heal":
        updates["health"] = min(100, (pet["health"] or 0) + 25)
        updates["last_healed_at"] = now
        xp_reward = 4

    updates["total_care_actions"] = (pet["total_care_actions"] or 0) + 1

    set_clause = ", ".join(f"{k} = ?" for k in updates)
    await db.execute(
        f"UPDATE user_pets SET {set_clause} WHERE id = ?",
        list(updates.values()) + [pet_id],
    )

    if xp_reward:
        await db.execute(
            "UPDATE avatar_stats SET current_xp = current_xp + ? WHERE user_id = ?",
            (xp_reward, user_id),
        )

    await db.commit()
    return {"pet_id": pet_id, "action": action, "xp_earned": xp_reward, **updates}


# ---------------------------------------------------------------------------
# World map
# ---------------------------------------------------------------------------

async def get_world_map(db: aiosqlite.Connection, user_id: int, user_tier: int) -> list:
    cursor = await db.execute(
        "SELECT level FROM avatar_stats WHERE user_id = ?", (user_id,)
    )
    avatar = await cursor.fetchone()
    user_level = avatar["level"] if avatar else 1

    cursor = await db.execute(
        """SELECT wmr.*,
                  CASE WHEN wmr.min_level <= ? AND COALESCE(wmr.requires_subscription_tier, 1) <= ?
                       THEN TRUE ELSE FALSE END as is_unlocked
           FROM world_map_regions wmr
           WHERE wmr.is_active = TRUE
           ORDER BY wmr.min_level""",
        (user_level, user_tier),
    )
    return await cursor.fetchall()


# ---------------------------------------------------------------------------
# Leaderboard
# ---------------------------------------------------------------------------

async def get_leaderboard(db: aiosqlite.Connection) -> list:
    cursor = await db.execute(
        """SELECT lb.*, u.username,
                  avs.level, avs.current_xp, avs.afya_points_balance
           FROM leaderboards lb
           JOIN users u ON lb.user_id = u.id
           JOIN avatar_stats avs ON lb.user_id = avs.user_id
           ORDER BY lb.health_score DESC, lb.rank ASC
           LIMIT 50""",
    )
    return await cursor.fetchall()
