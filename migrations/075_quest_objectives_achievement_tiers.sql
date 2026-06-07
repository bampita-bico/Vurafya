-- Migration 075: Quest Objectives + Achievement Tiers
-- Fills critical gap: 33 quests have zero objectives
-- Adds tiered achievements: Bronze/Silver/Gold/Platinum/Diamond

-- ============================================================================
-- QUEST OBJECTIVES (for existing 33 game_quests)
-- ~3 objectives per quest = ~99 entries
-- ============================================================================

-- Quest 1: Kidney-Safe Day (daily, CKD)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(1, 'Log 3 kidney-safe meals (PRAL ≤ 0)', 'meal_log_pral', 3, 1),
(1, 'Keep potassium intake under 2000mg', 'nutrient_limit', 2000, 2),
(1, 'Keep phosphorus intake under 800mg', 'nutrient_limit', 800, 3);

-- Quest 2: Low K/P Challenge (daily, CKD)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(2, 'Log all meals for the day', 'meal_count', 3, 1),
(2, 'Total potassium < 1500mg', 'nutrient_limit', 1500, 2),
(2, 'Total phosphorus < 700mg', 'nutrient_limit', 700, 3);

-- Quest 3: PRAL Perfect Day (daily, CKD)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(3, 'All meals must be PRAL-negative (alkalizing)', 'meal_pral_negative', 3, 1),
(3, 'Daily total PRAL ≤ -5.0', 'daily_pral_target', -5.0, 2),
(3, 'Include at least 2 different alkalizing food groups', 'food_variety', 2, 3);

-- Quest 4: Sodium Watch Day (daily, CKD)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(4, 'Log all meals with sodium tracking', 'meal_count', 3, 1),
(4, 'Total sodium < 2000mg', 'nutrient_limit', 2000, 2),
(4, 'Avoid processed food items', 'food_avoid_category', 0, 3);

-- Quest 5: 3-Day Water Sprint (daily, General)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(5, 'Log at least 8 glasses of water', 'hydration_log', 8, 1),
(5, 'Maintain hydration 3 consecutive days', 'streak_days', 3, 2),
(5, 'Log water intake before each meal', 'hydration_timing', 3, 3);

-- Quest 6: Perfect Day Challenge (daily, General)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(6, 'Log breakfast, lunch, and dinner', 'meal_count', 3, 1),
(6, 'All meals within calorie target', 'calorie_compliance', 1, 2),
(6, 'Log at least 1 snack', 'snack_log', 1, 3);

-- Quest 7: Med Adherence Day (daily, General)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(7, 'Take all scheduled medications on time', 'med_adherence', 100, 1),
(7, 'Log medication intake', 'med_log', 1, 2),
(7, 'Rate how you feel after medications', 'symptom_log', 1, 3);

-- Quest 8: Kidney Safe Week (weekly, CKD)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(8, 'Complete 5 Kidney-Safe Day quests', 'quest_completion', 5, 1),
(8, 'Average daily PRAL ≤ 0 for the week', 'weekly_pral_avg', 0, 2),
(8, 'Log at least 21 meals this week', 'meal_count', 21, 3);

-- Quest 9: PRAL Perfect Week (weekly, CKD)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(9, 'Achieve PRAL-negative on 5+ days', 'daily_pral_negative_count', 5, 1),
(9, 'Include 10+ unique alkalizing foods', 'unique_foods', 10, 2),
(9, 'Weekly average PRAL ≤ -3.0', 'weekly_pral_avg', -3.0, 3);

-- Quest 10: Dialysis Prep Week (weekly, CKD)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(10, 'Track fluid intake daily', 'hydration_log_days', 7, 1),
(10, 'Keep potassium under limit on 6+ days', 'nutrient_compliance_days', 6, 2),
(10, 'Log weight before and after dialysis sessions', 'weight_log', 2, 3);

-- Quest 11: CKD Med Perfect Week (weekly, CKD)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(11, '100% medication adherence for 7 days', 'med_adherence_streak', 7, 1),
(11, 'Take phosphate binders with every meal', 'binder_compliance', 21, 2),
(11, 'Log any side effects observed', 'side_effect_log', 1, 3);

-- Quest 12: Phosphate Binder Week (weekly, CKD)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(12, 'Take phosphate binders at every meal for 7 days', 'binder_compliance', 21, 1),
(12, 'Keep phosphorus under 800mg/day on 6+ days', 'nutrient_compliance_days', 6, 2),
(12, 'Log phosphorus-rich foods avoided', 'food_avoidance_log', 5, 3);

-- Quest 13: Glucose Control Week (weekly, Diabetes)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(13, 'Log blood glucose 2+ times daily for 7 days', 'glucose_log', 14, 1),
(13, 'Keep fasting glucose < 130mg/dL on 5+ days', 'glucose_compliance_days', 5, 2),
(13, 'Log all carbohydrate portions', 'carb_log', 21, 3);

-- Quest 14: Low GI Week (weekly, Diabetes)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(14, 'All main meals contain low-GI foods (GI<55)', 'low_gi_meals', 14, 1),
(14, 'Replace 3+ refined carb meals with whole grain', 'food_swap', 3, 2),
(14, 'Achieve stable glucose readings (variation <30mg/dL)', 'glucose_stability', 30, 3);

-- Quest 15: BP Perfect Week (weekly, Hypertension)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(15, 'Log blood pressure daily for 7 days', 'bp_log', 7, 1),
(15, 'Average systolic < 140 mmHg for the week', 'bp_avg_systolic', 140, 2),
(15, 'Keep sodium under 2000mg/day on 5+ days', 'nutrient_compliance_days', 5, 3);

-- Quest 16: DASH Diet Week (weekly, Hypertension)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(16, 'Eat 5+ servings of fruits/vegetables daily', 'food_servings', 35, 1),
(16, 'Include low-fat dairy 2+ times daily', 'food_category_log', 14, 2),
(16, 'Limit red meat to 2 or fewer servings this week', 'food_category_limit', 2, 3);

-- Quest 17: Protein Power Week (weekly, General)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(17, 'Hit protein target (g/kg body weight) on 5+ days', 'nutrient_compliance_days', 5, 1),
(17, 'Include protein source in every meal', 'protein_per_meal', 21, 2),
(17, 'Try 3 new protein-rich foods', 'new_foods', 3, 3);

-- Quest 18: Step God Challenge (weekly, General)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(18, 'Walk 10,000+ steps on 5+ days', 'step_count_days', 5, 1),
(18, 'Total 50,000+ steps for the week', 'weekly_steps', 50000, 2),
(18, 'Log at least one outdoor activity', 'activity_log', 1, 3);

-- Quest 19: Hydration Champion Week (weekly, General)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(19, 'Drink 8+ glasses of water daily for 7 days', 'hydration_streak', 7, 1),
(19, 'Limit sugary beverages to 2 or fewer this week', 'beverage_limit', 2, 2),
(19, 'Log water intake before every meal', 'hydration_timing_days', 7, 3);

-- Quest 20: CKD Diet Champion Month (monthly, CKD)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(20, 'Complete 4 Kidney Safe Week quests', 'quest_completion', 4, 1),
(20, 'Keep monthly average PRAL ≤ 0', 'monthly_pral_avg', 0, 2),
(20, 'Log meals on 25+ days', 'logging_days', 25, 3);

-- Quest 21: Kidney Function Improver (monthly, CKD)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(21, 'Track eGFR this month', 'lab_test', 1, 1),
(21, 'Maintain K+ and P within targets for 20+ days', 'nutrient_compliance_days', 20, 2),
(21, 'Achieve eGFR stability or improvement', 'lab_improvement', 0, 3);

-- Quest 22: CKD Med Perfect Month (monthly, CKD)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(22, '95%+ medication adherence for 30 days', 'med_adherence_pct', 95, 1),
(22, 'No missed phosphate binder doses', 'binder_compliance', 90, 2),
(22, 'Log any prescription changes with doctor', 'prescription_update', 1, 3);

-- Quest 23: PRAL Master Month (monthly, CKD)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(23, 'Average daily PRAL ≤ -3.0 for the month', 'monthly_pral_avg', -3.0, 1),
(23, 'Eat 50+ unique alkalizing foods', 'unique_foods', 50, 2),
(23, 'Complete all PRAL Perfect Week quests', 'quest_completion', 4, 3);

-- Quest 24: Glucose Control Master (monthly, Diabetes)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(24, 'Log blood glucose on 25+ days', 'glucose_log_days', 25, 1),
(24, 'Time-in-range >70%', 'glucose_time_in_range', 70, 2),
(24, 'Get HbA1c test this month', 'lab_test', 1, 3);

-- Quest 25: BP Stability Month (monthly, Hypertension)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(25, 'Log blood pressure on 25+ days', 'bp_log_days', 25, 1),
(25, 'Average systolic < 135 mmHg', 'bp_avg_systolic', 135, 2),
(25, 'Sodium under target on 20+ days', 'nutrient_compliance_days', 20, 3);

-- Quest 26: 30-Day Transformation (monthly, General)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(26, 'Log meals on 25+ days', 'logging_days', 25, 1),
(26, 'Complete 10+ quests of any type', 'quest_completion', 10, 2),
(26, 'Improve one health metric by 10%', 'metric_improvement', 10, 3);

-- Quest 27: Med Champion Month (monthly, General)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(27, '90%+ medication adherence for 30 days', 'med_adherence_pct', 90, 1),
(27, 'Never miss 2 doses in a row', 'max_consecutive_miss', 1, 2),
(27, 'Refill prescriptions before running out', 'refill_on_time', 1, 3);

-- Quest 28: World Kidney Day Sprint 2025 (seasonal, CKD)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(28, 'Log kidney-safe meals for 7 consecutive days', 'streak_days', 7, 1),
(28, 'Share CKD awareness content', 'social_share', 1, 2),
(28, 'Complete special kidney quiz', 'quiz_completion', 1, 3);

-- Quest 29: Ramadan Wellness Challenge (seasonal, General)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(29, 'Log Suhoor and Iftar meals daily', 'meal_count_daily', 2, 1),
(29, 'Maintain hydration during non-fasting hours', 'hydration_log', 8, 2),
(29, 'Keep balanced nutrition despite fasting schedule', 'nutrient_balance', 1, 3);

-- Quest 30: Diabetes Awareness Month (seasonal, Diabetes)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(30, 'Complete 5 glucose-related quests', 'quest_completion', 5, 1),
(30, 'Try 10 new low-GI foods', 'new_foods', 10, 2),
(30, 'Participate in community awareness activity', 'social_activity', 1, 3);

-- Quest 31: The Journey Begins (story, General)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(31, 'Create your avatar and choose a class', 'avatar_creation', 1, 1),
(31, 'Complete your health declaration', 'health_declaration', 1, 2),
(31, 'Log your first meal', 'first_meal', 1, 3),
(31, 'Explore Wellness Meadows region', 'region_visit', 1, 4);

-- Quest 32: Mastering CKD Nutrition (story, CKD)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(32, 'Learn about PRAL and log 5 alkalizing meals', 'tutorial_pral', 5, 1),
(32, 'Track potassium for 3 days and stay under limit', 'nutrient_compliance_days', 3, 2),
(32, 'Visit Renal Reef and defeat Phosphorus Phantom', 'boss_defeat', 1, 3),
(32, 'Achieve 7-day CKD diet compliance streak', 'compliance_streak', 7, 4);

-- Quest 33: Clinical Excellence (story, General)
INSERT OR IGNORE INTO quest_objectives (quest_id, description, objective_type, target_value, sequence_order) VALUES
(33, 'Book and complete first consultation', 'consultation_complete', 1, 1),
(33, 'Upload lab results', 'lab_upload', 1, 2),
(33, 'Follow doctor recommendations for 7 days', 'recommendation_compliance', 7, 3),
(33, 'Achieve improvement in tracked health metric', 'metric_improvement', 1, 4);

-- ============================================================================
-- ACHIEVEMENT TIERS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS achievement_tiers (
    id INTEGER PRIMARY KEY,
    achievement_id INTEGER NOT NULL REFERENCES achievements(id),
    tier_name VARCHAR(20) NOT NULL,
        -- Bronze, Silver, Gold, Platinum, Diamond
    tier_level INTEGER NOT NULL,
        -- 1=Bronze, 2=Silver, 3=Gold, 4=Platinum, 5=Diamond
    requirement_value REAL NOT NULL,
    requirement_description TEXT NOT NULL,
    xp_reward INTEGER NOT NULL,
    ap_reward INTEGER DEFAULT 0,
    cosmetic_reward_id INTEGER,
    title_reward VARCHAR(80),
    requires_subscription_tier INTEGER DEFAULT 1,
        -- Diamond tier = Pro only (tier 3)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(achievement_id, tier_level)
);

-- ============================================================================
-- USER ACHIEVEMENT TIER PROGRESS
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_achievement_tier_progress (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    achievement_id INTEGER NOT NULL REFERENCES achievements(id),
    current_tier_level INTEGER DEFAULT 0,
        -- 0=not started, 1=Bronze, 2=Silver, etc.
    current_value REAL DEFAULT 0,
    bronze_completed_at TIMESTAMP,
    silver_completed_at TIMESTAMP,
    gold_completed_at TIMESTAMP,
    platinum_completed_at TIMESTAMP,
    diamond_completed_at TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, achievement_id)
);

-- ============================================================================
-- SEED: ACHIEVEMENT TIERS
-- Representative tiers for key achievements (5 tiers x selected achievements)
-- ============================================================================

-- Achievement 1: Kidney Diet Master (ckd_nutrition, streak)
INSERT OR IGNORE INTO achievement_tiers (achievement_id, tier_name, tier_level, requirement_value, requirement_description, xp_reward, ap_reward, title_reward, requires_subscription_tier) VALUES
(1, 'Bronze', 1, 7, '7-day kidney-safe diet streak', 50, 10, NULL, 1),
(1, 'Silver', 2, 30, '30-day kidney-safe diet streak', 150, 30, 'Kidney Guardian', 1),
(1, 'Gold', 3, 90, '90-day kidney-safe diet streak', 500, 100, 'Kidney Protector', 1),
(1, 'Platinum', 4, 180, '180-day streak + eGFR stable/improved', 1000, 250, 'Kidney Champion', 1),
(1, 'Diamond', 5, 365, '365-day streak + community mentor', 2500, 500, 'Kidney Legend', 3);

-- Achievement 2: PRAL Pro 30-Day (ckd_nutrition, streak)
INSERT OR IGNORE INTO achievement_tiers (achievement_id, tier_name, tier_level, requirement_value, requirement_description, xp_reward, ap_reward, title_reward, requires_subscription_tier) VALUES
(2, 'Bronze', 1, 7, 'PRAL-negative for 7 days', 50, 10, NULL, 1),
(2, 'Silver', 2, 30, 'PRAL-negative for 30 days', 150, 30, 'Acid Balancer', 1),
(2, 'Gold', 3, 90, 'PRAL-negative for 90 days', 500, 100, 'PRAL Master', 1),
(2, 'Platinum', 4, 180, 'PRAL ≤ -3.0 avg for 180 days', 1000, 250, 'Alkaline Champion', 1),
(2, 'Diamond', 5, 365, 'PRAL ≤ -5.0 avg for 365 days', 2500, 500, 'Alkaline Legend', 3);

-- Achievement 15: Glucose Guardian (diabetes, count)
INSERT OR IGNORE INTO achievement_tiers (achievement_id, tier_name, tier_level, requirement_value, requirement_description, xp_reward, ap_reward, title_reward, requires_subscription_tier) VALUES
(15, 'Bronze', 1, 50, 'Log glucose 50 times', 50, 10, NULL, 1),
(15, 'Silver', 2, 200, 'Log glucose 200 times', 150, 30, 'Glucose Tracker', 1),
(15, 'Gold', 3, 500, 'Log glucose 500 times with >70% in range', 500, 100, 'Glucose Master', 1),
(15, 'Platinum', 4, 1000, '1000 logs + HbA1c improvement', 1000, 250, 'Glucose Champion', 1),
(15, 'Diamond', 5, 2000, '2000 logs + sustained HbA1c <7%', 2500, 500, 'Glucose Legend', 3);

-- Achievement 19: BP Tracker (hypertension, count)
INSERT OR IGNORE INTO achievement_tiers (achievement_id, tier_name, tier_level, requirement_value, requirement_description, xp_reward, ap_reward, title_reward, requires_subscription_tier) VALUES
(19, 'Bronze', 1, 30, 'Log blood pressure 30 times', 50, 10, NULL, 1),
(19, 'Silver', 2, 100, 'Log BP 100 times', 150, 30, 'BP Monitor', 1),
(19, 'Gold', 3, 300, 'Log BP 300 times + avg <140 systolic', 500, 100, 'BP Controller', 1),
(19, 'Platinum', 4, 600, '600 logs + sustained BP control', 1000, 250, 'BP Champion', 1),
(19, 'Diamond', 5, 1000, '1000 logs + community BP challenge wins', 2500, 500, 'BP Legend', 3);

-- Achievement 23: First Meal Logged (nutrition, milestone)
INSERT OR IGNORE INTO achievement_tiers (achievement_id, tier_name, tier_level, requirement_value, requirement_description, xp_reward, ap_reward, title_reward, requires_subscription_tier) VALUES
(23, 'Bronze', 1, 1, 'Log your first meal', 25, 5, NULL, 1),
(23, 'Silver', 2, 50, 'Log 50 meals', 100, 20, 'Meal Logger', 1),
(23, 'Gold', 3, 200, 'Log 200 meals with full nutrition data', 300, 60, 'Nutrition Tracker', 1),
(23, 'Platinum', 4, 500, '500 meals + consistent macros', 750, 150, 'Nutrition Pro', 1),
(23, 'Diamond', 5, 1000, '1000 meals + helped 5 others log meals', 2000, 400, 'Nutrition Mentor', 3);

-- Achievement 26: 100 Meals (nutrition, count)
INSERT OR IGNORE INTO achievement_tiers (achievement_id, tier_name, tier_level, requirement_value, requirement_description, xp_reward, ap_reward, title_reward, requires_subscription_tier) VALUES
(26, 'Bronze', 1, 100, 'Log 100 meals', 75, 15, NULL, 1),
(26, 'Silver', 2, 500, 'Log 500 meals', 200, 40, 'Dedicated Eater', 1),
(26, 'Gold', 3, 1000, 'Log 1000 meals', 600, 120, 'Meal Master', 1),
(26, 'Platinum', 4, 2500, '2500 meals + 50+ unique foods', 1200, 250, 'Food Explorer', 1),
(26, 'Diamond', 5, 5000, '5000 meals + perfect week every month', 3000, 600, 'Food Legend', 3);

-- Achievement 29: Hydration Hero (hydration, streak)
INSERT OR IGNORE INTO achievement_tiers (achievement_id, tier_name, tier_level, requirement_value, requirement_description, xp_reward, ap_reward, title_reward, requires_subscription_tier) VALUES
(29, 'Bronze', 1, 7, 'Hit hydration target 7 days straight', 50, 10, NULL, 1),
(29, 'Silver', 2, 30, '30-day hydration streak', 150, 30, 'Water Warrior', 1),
(29, 'Gold', 3, 90, '90-day hydration streak', 500, 100, 'Hydration Master', 1),
(29, 'Platinum', 4, 180, '180-day streak + electrolyte balance', 1000, 250, 'Hydration Champion', 1),
(29, 'Diamond', 5, 365, '365-day streak', 2500, 500, 'Hydration Legend', 3);

-- Achievement 35: Med Adherence Week (clinical, streak)
INSERT OR IGNORE INTO achievement_tiers (achievement_id, tier_name, tier_level, requirement_value, requirement_description, xp_reward, ap_reward, title_reward, requires_subscription_tier) VALUES
(35, 'Bronze', 1, 7, '7-day perfect med adherence', 50, 10, NULL, 1),
(35, 'Silver', 2, 30, '30-day 95%+ adherence', 150, 30, 'Med Warrior', 1),
(35, 'Gold', 3, 90, '90-day 95%+ adherence', 500, 100, 'Med Master', 1),
(35, 'Platinum', 4, 180, '180-day perfect adherence', 1000, 250, 'Med Champion', 1),
(35, 'Diamond', 5, 365, '365-day perfect adherence + doctor verified', 2500, 500, 'Med Legend', 3);

-- Achievement 40: 7-Day Streak (milestone, streak)
INSERT OR IGNORE INTO achievement_tiers (achievement_id, tier_name, tier_level, requirement_value, requirement_description, xp_reward, ap_reward, title_reward, requires_subscription_tier) VALUES
(40, 'Bronze', 1, 7, 'Achieve 7-day streak', 50, 10, NULL, 1),
(40, 'Silver', 2, 14, 'Achieve 14-day streak', 100, 20, 'Consistent', 1),
(40, 'Gold', 3, 30, 'Achieve 30-day streak', 300, 60, 'Devoted', 1),
(40, 'Platinum', 4, 90, 'Achieve 90-day streak', 750, 150, 'Unstoppable', 1),
(40, 'Diamond', 5, 365, 'Achieve 365-day streak', 2500, 500, 'Immortal Streak', 3);

-- Achievement 41: 30-Day Legend (milestone, streak)
INSERT OR IGNORE INTO achievement_tiers (achievement_id, tier_name, tier_level, requirement_value, requirement_description, xp_reward, ap_reward, title_reward, requires_subscription_tier) VALUES
(41, 'Bronze', 1, 30, '30-day logging streak', 100, 20, NULL, 1),
(41, 'Silver', 2, 60, '60-day logging streak', 250, 50, 'Determined', 1),
(41, 'Gold', 3, 120, '120-day logging streak', 700, 140, 'Relentless', 1),
(41, 'Platinum', 4, 250, '250-day logging streak', 1500, 300, 'Legendary', 1),
(41, 'Diamond', 5, 500, '500-day logging streak', 3500, 700, 'Immortal', 3);

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT 'quest_objectives' AS tbl, COUNT(*) AS rows FROM quest_objectives
UNION ALL
SELECT 'achievement_tiers', COUNT(*) FROM achievement_tiers
UNION ALL
SELECT 'user_achievement_tier_progress', COUNT(*) FROM user_achievement_tier_progress;
