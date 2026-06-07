-- Migration 085: XP Rules Expansion + Subscription Gating
-- Wire new features into XP system
-- Gate existing content tables with subscription tier

-- ============================================================================
-- NEW XP EARNING RULES FOR NEW FEATURES
-- ============================================================================

INSERT OR IGNORE INTO xp_earning_rules (action_type, base_xp, streak_multiplier_formula, quality_multiplier_formula, requires_verification, max_per_day, max_per_week, cooldown_hours, category, description, example_scenario, is_active) VALUES
-- Boss encounters
('boss_defeat_normal', 200, '1.0 + (streak_days * 0.02)', '1.0 + (boss_difficulty * 0.3)', FALSE, 3, 10, 0, 'boss',
 'XP for defeating a boss on Normal difficulty', 'Defeat Phosphorus Phantom: 200 base XP', TRUE),
('boss_defeat_hard', 400, '1.0 + (streak_days * 0.02)', '1.0 + (boss_difficulty * 0.3)', FALSE, 2, 5, 0, 'boss',
 'XP for defeating a boss on Hard difficulty', 'Defeat Sugar Dragon on Hard: 400 base XP', TRUE),
('boss_defeat_nightmare', 750, '1.0 + (streak_days * 0.02)', '1.0 + (boss_difficulty * 0.3)', FALSE, 1, 3, 0, 'boss',
 'XP for defeating a boss on Nightmare difficulty', 'Defeat Uremia Dragon on Nightmare: 750 base XP', TRUE),

-- Guild activities
('guild_challenge_contribute', 15, '1.0', '1.0 + (contribution_rank * 0.1)', FALSE, 5, 30, 0, 'guild',
 'XP per contribution to guild challenge', 'Contribute meals to guild challenge: 15 XP each', TRUE),
('guild_challenge_complete', 100, '1.0', '1.0', FALSE, 1, 3, 0, 'guild',
 'XP for completing a guild challenge', 'Guild completes "10K Meals" challenge: 100 XP per member', TRUE),
('guild_rank_up', 250, '1.0', '1.0', FALSE, 1, 1, 168, 'guild',
 'XP for ranking up in guild', 'Promoted from Initiate to Member: 250 XP', TRUE),

-- Crafting
('crafting_common', 5, '1.0', '1.0', FALSE, 10, 50, 0, 'crafting',
 'XP for crafting Common quality item', 'Craft a Common potion: 5 XP', TRUE),
('crafting_uncommon', 10, '1.0', '1.0', FALSE, 10, 50, 0, 'crafting',
 'XP for crafting Uncommon quality item', 'Craft Uncommon: 10 XP', TRUE),
('crafting_rare', 25, '1.0', '1.0', FALSE, 5, 25, 0, 'crafting',
 'XP for crafting Rare quality item', 'Craft Rare: 25 XP', TRUE),
('crafting_epic', 50, '1.0', '1.0', FALSE, 3, 15, 0, 'crafting',
 'XP for crafting Epic quality item', 'Craft Epic: 50 XP', TRUE),
('crafting_legendary', 100, '1.0', '1.0', FALSE, 1, 5, 0, 'crafting',
 'XP for crafting Legendary quality item', 'Craft Legendary: 100 XP', TRUE),
('crafting_mastery_up', 150, '1.0', '1.0', FALSE, 1, 3, 0, 'crafting',
 'XP for increasing crafting mastery level', 'Reach Mastery Level 3 in potions: 150 XP', TRUE),

-- Pet companion
('pet_feed', 5, '1.0', '1.0', FALSE, 5, 30, 0, 'pet',
 'XP for feeding pet (via meal logging)', 'Log meal → pet fed: 5 XP', TRUE),
('pet_play', 5, '1.0', '1.0', FALSE, 3, 15, 4, 'pet',
 'XP for playing with pet (via exercise)', 'Log exercise → pet plays: 5 XP', TRUE),
('pet_evolve', 500, '1.0', '1.0', FALSE, 1, 1, 0, 'pet',
 'XP for evolving pet to next stage', 'Pet evolves to Adult stage: 500 XP', TRUE),
('pet_mythic_evolve', 2000, '1.0', '1.0', FALSE, 1, 1, 0, 'pet',
 'XP for evolving pet to Mythic stage', 'Pet reaches Mythic: 2000 XP', TRUE),

-- Daily login
('daily_login', 10, '1.0 + (streak_days * 0.05)', '1.0', FALSE, 1, 7, 20, 'login',
 'XP for daily login', 'Login today: 10 base XP (+ streak bonus)', TRUE),
('daily_login_milestone', 100, '1.0', '1.0', FALSE, 1, 1, 0, 'login',
 'XP for hitting login streak milestone', 'Hit 7-day login streak: 100 XP', TRUE),

-- World map
('region_discover', 25, '1.0', '1.0', FALSE, 5, 20, 0, 'exploration',
 'XP for discovering new content in a region', 'Discover Alkaline Forge in Renal Reef: 25 XP', TRUE),
('region_complete', 500, '1.0', '1.0', FALSE, 1, 2, 0, 'exploration',
 'XP for completing a region (100% exploration)', 'Complete Renal Reef: 500 XP', TRUE),
('region_master', 1000, '1.0', '1.0', FALSE, 1, 1, 0, 'exploration',
 'XP for mastering a region (all quests + bosses + achievements)', 'Master Renal Reef: 1000 XP', TRUE),

-- Health declaration
('health_declaration', 100, '1.0', '1.0', FALSE, 1, 1, 0, 'onboarding',
 'One-time XP for completing health declaration', 'Complete health declaration: 100 XP', TRUE),

-- Achievement tiers
('achievement_bronze', 50, '1.0', '1.0', FALSE, 5, 20, 0, 'achievement',
 'XP for earning Bronze tier achievement', 'Earn Bronze Kidney Diet Master: 50 XP', TRUE),
('achievement_silver', 150, '1.0', '1.0', FALSE, 3, 10, 0, 'achievement',
 'XP for earning Silver tier', 'Earn Silver: 150 XP', TRUE),
('achievement_gold', 500, '1.0', '1.0', FALSE, 2, 5, 0, 'achievement',
 'XP for earning Gold tier', 'Earn Gold: 500 XP', TRUE),
('achievement_platinum', 1000, '1.0', '1.0', FALSE, 1, 3, 0, 'achievement',
 'XP for earning Platinum tier', 'Earn Platinum: 1000 XP', TRUE),
('achievement_diamond', 2500, '1.0', '1.0', FALSE, 1, 1, 0, 'achievement',
 'XP for earning Diamond tier (Pro only)', 'Earn Diamond: 2500 XP', TRUE);

-- ============================================================================
-- SUBSCRIPTION GATING: ALTER EXISTING CONTENT TABLES
-- ============================================================================

-- Gate game_quests (story quests = Plus, some monthly = Pro)
ALTER TABLE game_quests ADD COLUMN requires_subscription_tier INTEGER DEFAULT 1;
UPDATE game_quests SET requires_subscription_tier = 2 WHERE quest_type = 'story';
UPDATE game_quests SET requires_subscription_tier = 2 WHERE quest_type = 'seasonal';

-- Gate achievements (Diamond tier tracked in achievement_tiers table, not here)
ALTER TABLE achievements ADD COLUMN requires_subscription_tier INTEGER DEFAULT 1;

-- Gate avatar_cosmetic_shop (premium cosmetics)
ALTER TABLE avatar_cosmetic_shop ADD COLUMN requires_subscription_tier INTEGER DEFAULT 1;
UPDATE avatar_cosmetic_shop SET requires_subscription_tier = 2 WHERE is_premium = TRUE;
UPDATE avatar_cosmetic_shop SET requires_subscription_tier = 3 WHERE is_season_exclusive = TRUE;

-- Gate seasonal_events
-- Note: seasonal_events table may not exist or have different schema
-- Using IF EXISTS pattern via INSERT-only approach

-- ============================================================================
-- CONDITION FILTER ON GAME CONTENT
-- ============================================================================

-- game_quests already has condition_focus column
-- Add condition_filter to achievements
ALTER TABLE achievements ADD COLUMN condition_filter VARCHAR(60);
UPDATE achievements SET condition_filter = 'CKD' WHERE category LIKE 'ckd_%';
UPDATE achievements SET condition_filter = 'Diabetes' WHERE category = 'diabetes';
UPDATE achievements SET condition_filter = 'Hypertension' WHERE category = 'hypertension';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT 'xp_earning_rules' AS tbl, COUNT(*) AS rows FROM xp_earning_rules;
