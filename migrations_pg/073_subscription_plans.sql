-- Migration 073: Subscription Plans & Feature Gates
-- Foundation for monetization - everything references subscription tiers
-- Tiers: 1=Afya Free ($0), 2=Afya Plus (~$4/mo), 3=Afya Pro (~$12/mo)

-- ============================================================================
-- ENHANCE EXISTING SUBSCRIPTION_PLANS TABLE
-- (Table exists but is empty and missing tier column)
-- ============================================================================

ALTER TABLE subscription_plans ADD COLUMN tier INTEGER DEFAULT 1;
ALTER TABLE subscription_plans ADD COLUMN price_monthly_usd DOUBLE PRECISION DEFAULT 0.0;
ALTER TABLE subscription_plans ADD COLUMN price_annual_usd DOUBLE PRECISION DEFAULT 0.0;
ALTER TABLE subscription_plans ADD COLUMN trial_days INTEGER DEFAULT 0;
ALTER TABLE subscription_plans ADD COLUMN badge_label VARCHAR(40);
ALTER TABLE subscription_plans ADD COLUMN color_hex VARCHAR(10);
ALTER TABLE subscription_plans ADD COLUMN sort_order INTEGER DEFAULT 0;

-- ============================================================================
-- USER SUBSCRIPTIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_subscriptions (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    plan_id INTEGER NOT NULL REFERENCES subscription_plans(id),
    status VARCHAR(20) NOT NULL DEFAULT 'active',
        -- active, trial, paused, cancelled, expired
    billing_cycle VARCHAR(10) NOT NULL DEFAULT 'monthly',
        -- monthly, annual
    current_period_start DATE NOT NULL,
    current_period_end DATE NOT NULL,
    trial_end_date DATE,
    cancelled_at TIMESTAMP,
    cancellation_reason TEXT,
    auto_renew BOOLEAN DEFAULT TRUE,
    payment_method VARCHAR(40),
        -- mobile_money, card, afya_points, hybrid
    currency_code VARCHAR(10) DEFAULT 'UGX',
    amount_paid DOUBLE PRECISION DEFAULT 0.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- SUBSCRIPTION FEATURES (Feature Gate Matrix)
-- ============================================================================

CREATE TABLE IF NOT EXISTS subscription_features (
    id INTEGER PRIMARY KEY,
    feature_key VARCHAR(80) NOT NULL UNIQUE,
    feature_name VARCHAR(120) NOT NULL,
    category VARCHAR(40) NOT NULL,
        -- nutrition, game, medical, social, commerce
    required_tier INTEGER NOT NULL DEFAULT 1,
        -- 1=free, 2=plus, 3=pro
    free_limit INTEGER,
        -- NULL = unlimited at tier, number = daily/weekly cap for free users
    plus_limit INTEGER,
    pro_limit INTEGER,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- SUBSCRIPTION TRANSACTIONS (Payment History + Receipts)
-- ============================================================================

CREATE TABLE IF NOT EXISTS subscription_transactions (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    subscription_id INTEGER REFERENCES user_subscriptions(id),
    plan_id INTEGER NOT NULL REFERENCES subscription_plans(id),
    transaction_type VARCHAR(20) NOT NULL,
        -- new, renewal, upgrade, downgrade, refund
    amount_ugx DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    amount_usd DOUBLE PRECISION,
    currency_code VARCHAR(10) DEFAULT 'UGX',
    payment_method VARCHAR(40),
    payment_reference VARCHAR(200),
    receipt_number VARCHAR(60) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'completed',
        -- pending, completed, failed, refunded
    billing_period_start DATE,
    billing_period_end DATE,
    platform_revenue_ugx DOUBLE PRECISION DEFAULT 0.0,
    tax_amount_ugx DOUBLE PRECISION DEFAULT 0.0,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- SEED DATA: 3 SUBSCRIPTION PLANS
-- ============================================================================

INSERT INTO subscription_plans (id, plan_name, description, price_monthly_ugx, price_annual_ugx, price_monthly_usd, price_annual_usd, tier, features, max_consultations, ai_features_enabled, lab_discounts_pct, pharmacy_discounts_pct, trial_days, badge_label, color_hex, sort_order, is_active, created_at)
VALUES
(1, 'Afya Free',
 'Basic health tracking. Log meals, track basic nutrients, play starter quests. Perfect for exploring Vurafya.',
 0.0, 0.0, 0.0, 0.0, 1,
 '["basic_meal_logging","basic_quests","basic_achievements","2_world_regions","1_daily_recommendation","view_meal_plans","basic_crafting"]',
 1, FALSE, 0.0, 0.0, 0, 'FREE', '#6B7280', 1, TRUE, CURRENT_TIMESTAMP),

(2, 'Afya Plus',
 'Full nutrition tracking with personalized recommendations. Join guilds, get a pet companion, unlock 6 world regions. Ad-free experience.',
 15000.0, 150000.0, 4.0, 40.0, 2,
 '["unlimited_meal_logging","unlimited_recommendations","5_weekly_meal_plans","full_crafting","1_pet","guild_join","6_world_regions","lab_recommendations","ad_free","priority_support"]',
 5, TRUE, 5.0, 5.0, 7, 'PLUS', '#3B82F6', 2, TRUE, CURRENT_TIMESTAMP),

(3, 'Afya Pro',
 'Complete health mastery. Boss encounters, guild creation, 3 pets, all world regions. Doctor game stat access. Priority consultations. The ultimate CKD/health management tool.',
 45000.0, 450000.0, 12.0, 120.0, 3,
 '["everything_in_plus","boss_encounters","guild_creation","3_pets","rare_crafting","all_world_regions","doctor_game_access","priority_consultations","exclusive_cosmetics","monthly_health_report","dedicated_support"]',
 999, TRUE, 15.0, 10.0, 14, 'PRO', '#F59E0B', 3, TRUE, CURRENT_TIMESTAMP);

-- ============================================================================
-- SEED DATA: FEATURE GATE MATRIX (~40 entries)
-- ============================================================================

INSERT INTO subscription_features (feature_key, feature_name, category, required_tier, free_limit, plus_limit, pro_limit, description) VALUES
-- NUTRITION FEATURES
('meal_logging', 'Meal Logging', 'nutrition', 1, NULL, NULL, NULL, 'Log meals and track nutrients'),
('food_recommendations', 'Food Recommendations', 'nutrition', 1, 1, NULL, NULL, 'Personalized food suggestions (free: 1/day)'),
('meal_plans', 'Meal Plans', 'nutrition', 1, 0, 5, NULL, 'Curated meal plans (free: view only, plus: 5/week)'),
('lab_driven_recommendations', 'Lab-Driven Recommendations', 'nutrition', 2, 0, NULL, NULL, 'Recommendations based on lab results'),
('monthly_health_report', 'Monthly Health Report', 'nutrition', 3, 0, 0, NULL, 'Detailed monthly health analysis PDF'),
('advanced_pral_tracking', 'Advanced PRAL Tracking', 'nutrition', 2, 0, NULL, NULL, 'Full PRAL analysis with component breakdown'),
('3p_daily_dashboard', '3P Daily Dashboard', 'nutrition', 2, 0, NULL, NULL, 'Daily protein/potassium/phosphorus tracking'),
('weekly_trend_alerts', 'Weekly Trend Alerts', 'nutrition', 2, 0, NULL, NULL, 'Automated alerts for rapid nutrient changes'),

-- GAME FEATURES
('basic_quests', 'Basic Quests', 'game', 1, NULL, NULL, NULL, 'Daily and weekly quests'),
('story_quests', 'Story Quests', 'game', 2, 0, NULL, NULL, 'Narrative-driven quest chains'),
('boss_encounters', 'Boss Encounters', 'game', 3, 0, 0, NULL, 'Fight health condition bosses'),
('guild_join', 'Join Guilds', 'game', 2, 0, NULL, NULL, 'Join health-focused guilds'),
('guild_creation', 'Create Guilds', 'game', 3, 0, 0, NULL, 'Create and lead guilds'),
('crafting_basic', 'Basic Crafting', 'game', 1, NULL, NULL, NULL, 'Craft Common/Uncommon items'),
('crafting_full', 'Full Crafting', 'game', 2, 0, NULL, NULL, 'Craft up to Rare quality'),
('crafting_legendary', 'Legendary Crafting', 'game', 3, 0, 0, NULL, 'Craft Epic/Legendary items'),
('pet_companion', 'Pet Companion', 'game', 2, 0, 1, 3, 'Virtual health pet (plus: 1, pro: 3)'),
('world_map_free', 'World Map (Free Regions)', 'game', 1, 2, 6, 10, 'Explore health regions'),
('achievement_diamond', 'Diamond Achievement Tier', 'game', 3, 0, 0, NULL, 'Unlock Diamond achievement tier'),
('daily_login_rewards', 'Daily Login Rewards', 'game', 1, NULL, NULL, NULL, 'Basic daily login rewards'),
('daily_login_premium', 'Premium Login Rewards', 'game', 2, 0, NULL, NULL, '2x rewards + exclusive cosmetics'),
('exclusive_cosmetics', 'Exclusive Cosmetics', 'game', 3, 0, 0, NULL, 'Pro-only avatar cosmetics'),
('seasonal_events_premium', 'Premium Seasonal Events', 'game', 2, 0, NULL, NULL, 'Access premium seasonal content'),

-- MEDICAL FEATURES
('basic_consultation', 'Basic Consultation', 'medical', 1, 1, 5, 999, 'Book doctor consultations'),
('priority_consultation', 'Priority Consultation', 'medical', 3, 0, 0, NULL, 'Skip queue for faster matching'),
('doctor_game_stat_access', 'Doctor Game Stat Sharing', 'medical', 3, 0, 0, NULL, 'Share game/health stats with doctor'),
('specialist_referrals', 'Specialist Referrals', 'medical', 2, 0, NULL, NULL, 'Get specialist referrals'),
('lab_booking', 'Lab Test Booking', 'medical', 1, NULL, NULL, NULL, 'Book lab tests through platform'),
('pharmacy_ordering', 'Pharmacy Ordering', 'medical', 1, NULL, NULL, NULL, 'Order medications through platform'),

-- SOCIAL FEATURES
('basic_social', 'Basic Social', 'social', 1, NULL, NULL, NULL, 'Friends list and basic interactions'),
('community_chat', 'Community Chat', 'social', 1, NULL, NULL, NULL, 'Participate in community discussions'),
('guild_chat', 'Guild Chat', 'social', 2, 0, NULL, NULL, 'Chat within guild'),
('leaderboard_access', 'Leaderboards', 'game', 1, NULL, NULL, NULL, 'View and compete on leaderboards'),

-- COMMERCE FEATURES
('ad_free', 'Ad-Free Experience', 'commerce', 2, 0, NULL, NULL, 'No advertisements'),
('lab_discount', 'Lab Test Discounts', 'commerce', 2, 0, NULL, NULL, '5% Plus / 15% Pro discount on labs'),
('pharmacy_discount', 'Pharmacy Discounts', 'commerce', 2, 0, NULL, NULL, '5% Plus / 10% Pro discount on orders'),
('priority_support', 'Priority Support', 'commerce', 2, 0, NULL, NULL, 'Faster customer support response'),
('dedicated_support', 'Dedicated Support', 'commerce', 3, 0, 0, NULL, 'Personal health support agent');

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT 'subscription_plans' AS tbl, COUNT(*) AS rows FROM subscription_plans
UNION ALL
SELECT 'user_subscriptions', COUNT(*) FROM user_subscriptions
UNION ALL
SELECT 'subscription_features', COUNT(*) FROM subscription_features
UNION ALL
SELECT 'subscription_transactions', COUNT(*) FROM subscription_transactions;
