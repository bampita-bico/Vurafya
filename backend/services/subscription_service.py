import aiosqlite
from datetime import datetime, timezone


async def get_plans(db: aiosqlite.Connection) -> list:
    cursor = await db.execute(
        """SELECT id, plan_name, description, tier, price_monthly_ugx, price_annual_ugx,
                  price_monthly_usd, price_annual_usd, trial_days, badge_label, color_hex,
                  features, max_consultations, ai_features_enabled,
                  lab_discounts_pct, pharmacy_discounts_pct
           FROM subscription_plans WHERE is_active = TRUE ORDER BY sort_order"""
    )
    return await cursor.fetchall()


async def get_user_subscription(db: aiosqlite.Connection, user_id: int) -> dict | None:
    cursor = await db.execute(
        """SELECT us.*, sp.plan_name, sp.tier, sp.price_monthly_ugx, sp.price_monthly_usd,
                  sp.badge_label, sp.color_hex, sp.features
           FROM user_subscriptions us
           JOIN subscription_plans sp ON us.plan_id = sp.id
           WHERE us.user_id = ? AND us.status IN ('active', 'trial')
           ORDER BY us.created_at DESC LIMIT 1""",
        (user_id,),
    )
    return await cursor.fetchone()


async def get_user_tier(db: aiosqlite.Connection, user_id: int) -> int:
    sub = await get_user_subscription(db, user_id)
    return sub["tier"] if sub else 1


async def check_feature_access(db: aiosqlite.Connection, user_id: int, feature_key: str) -> dict:
    user_tier = await get_user_tier(db, user_id)

    cursor = await db.execute(
        "SELECT * FROM subscription_features WHERE feature_key = ?", (feature_key,)
    )
    feature = await cursor.fetchone()
    if not feature:
        return {"allowed": True, "limit": None, "feature_key": feature_key,
                "required_tier": 1, "user_tier": user_tier}

    allowed = user_tier >= feature["required_tier"]
    limit = None
    if user_tier == 1:
        limit = feature["free_limit"]
    elif user_tier == 2:
        limit = feature["plus_limit"]
    elif user_tier == 3:
        limit = feature["pro_limit"]

    return {
        "allowed": allowed,
        "limit": limit,
        "feature_key": feature_key,
        "required_tier": feature["required_tier"],
        "user_tier": user_tier,
    }


async def get_all_features_for_user(db: aiosqlite.Connection, user_id: int) -> list:
    user_tier = await get_user_tier(db, user_id)

    cursor = await db.execute(
        "SELECT * FROM subscription_features WHERE is_active = TRUE ORDER BY category, feature_name"
    )
    features = await cursor.fetchall()

    result = []
    for f in features:
        allowed = user_tier >= f["required_tier"]
        limit = None
        if user_tier == 1:
            limit = f["free_limit"]
        elif user_tier == 2:
            limit = f["plus_limit"]
        elif user_tier == 3:
            limit = f["pro_limit"]

        result.append({**f, "allowed": allowed, "user_limit": limit, "user_tier": user_tier})
    return result


async def upgrade_subscription(db: aiosqlite.Connection, user_id: int, plan_id: int, billing_cycle: str) -> dict:
    now = datetime.now(timezone.utc).isoformat()

    # Get plan
    cursor = await db.execute("SELECT * FROM subscription_plans WHERE id = ? AND is_active = TRUE", (plan_id,))
    plan = await cursor.fetchone()
    if not plan:
        return {"error": "Plan not found"}

    # Deactivate current subscription
    await db.execute(
        "UPDATE user_subscriptions SET status = 'expired', updated_at = ? WHERE user_id = ? AND status IN ('active', 'trial')",
        (now, user_id),
    )

    # Create new subscription
    period_end = "date('now', '+1 month')" if billing_cycle == "monthly" else "date('now', '+1 year')"
    await db.execute(
        f"""INSERT INTO user_subscriptions (user_id, plan_id, status, billing_cycle,
            current_period_start, current_period_end, amount_paid, created_at, updated_at)
            VALUES (?, ?, 'active', ?, date('now'), {period_end}, ?, ?, ?)""",
        (user_id, plan_id, billing_cycle,
         plan["price_monthly_ugx"] if billing_cycle == "monthly" else plan["price_annual_ugx"],
         now, now),
    )

    # Create transaction record
    amount = plan["price_monthly_ugx"] if billing_cycle == "monthly" else plan["price_annual_ugx"]
    await db.execute(
        """INSERT INTO subscription_transactions (user_id, plan_id, transaction_type,
           amount_ugx, receipt_number, status, created_at)
           VALUES (?, ?, 'new', ?, ?, 'completed', ?)""",
        (user_id, plan_id, amount, f"SUB-{user_id}-{plan_id}-{int(datetime.now().timestamp())}", now),
    )

    await db.commit()
    return {"plan": plan["plan_name"], "tier": plan["tier"], "billing_cycle": billing_cycle}
