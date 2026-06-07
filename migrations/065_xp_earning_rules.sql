-- Migration 065: XP Earning Rules
-- Comprehensive XP system for all user actions
-- Multipliers for streaks, quality, and difficulty
-- Part of Avatar-Health Integration (Phase 3)

-- ============================================================================
-- XP EARNING RULES TABLE
-- ============================================================================
-- Defines base XP and multipliers for all earnable actions

CREATE TABLE xp_earning_rules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    action_type VARCHAR(50) NOT NULL UNIQUE,
    base_xp INTEGER NOT NULL,

    -- Multiplier formulas (evaluated in application layer)
    streak_multiplier_formula TEXT,  -- "1.0 + (streak_days * 0.05)" capped at 2.0x
    quality_multiplier_formula TEXT,  -- "1.0 + (data_quality_score * 0.5)"
    difficulty_multiplier_formula TEXT,  -- Based on user's health condition severity

    -- Rate limiting (prevent farming)
    requires_verification BOOLEAN DEFAULT FALSE,
    max_per_day INTEGER,  -- NULL = unlimited
    max_per_week INTEGER,
    cooldown_hours INTEGER,  -- Minimum time between same action

    -- Categorization
    category VARCHAR(50) NOT NULL,  -- meal_logging / lab_entry / biometric / medication / social / achievement

    -- Description
    description TEXT NOT NULL,
    example_scenario TEXT,

    -- Metadata
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CHECK (base_xp >= 0)
);

CREATE INDEX idx_xp_rules_category ON xp_earning_rules(category, is_active);
CREATE INDEX idx_xp_rules_active ON xp_earning_rules(is_active);


-- ============================================================================
-- SEED DATA: XP Earning Rules
-- ============================================================================

-- === MEAL LOGGING (Daily core activity) ===

INSERT OR IGNORE INTO xp_earning_rules VALUES
(1, 'meal_logged_complete', 20,
    '1.0 + (streak_days * 0.05)',  -- Up to 2.0x at 20-day streak
    '1.0 + (data_quality * 0.5)',  -- Up to 1.5x for complete data
    NULL,
    FALSE, 10, NULL, 0,
    'meal_logging',
    'Log complete meal with all components and quantities',
    'User logs "Breakfast: 2 eggs (100g), 1 slice bread (30g), 1 cup tea (240ml)" → 20 XP base, +5 XP for 5-day streak, +10 XP for high data quality = 35 XP total',
    TRUE, CURRENT_TIMESTAMP);

INSERT OR IGNORE INTO xp_earning_rules VALUES
(2, 'meal_logged_with_portions', 30,
    '1.0 + (streak_days * 0.05)',
    NULL, NULL,
    FALSE, 5, NULL, 0,
    'meal_logging',
    'Log meal with accurate portion sizes (not just "1 plate")',
    'User specifies exact grams instead of generic portions',
    TRUE, CURRENT_TIMESTAMP);

INSERT OR IGNORE INTO xp_earning_rules VALUES
(3, 'meal_logged_with_cooking_method', 40,
    '1.0 + (streak_days * 0.05)',
    NULL, NULL,
    FALSE, 3, NULL, 0,
    'meal_logging',
    'Log meal with cooking method specified for better nutrition calculation',
    'User specifies "boiled" vs "fried" sweet potatoes',
    TRUE, CURRENT_TIMESTAMP);

INSERT OR IGNORE INTO xp_earning_rules VALUES
(4, 'recipe_used', 15,
    NULL, NULL, NULL,
    FALSE, 10, NULL, 0,
    'meal_logging',
    'Log meal using a recipe (easier than component-by-component)',
    'User selects "Ugali with Sukuma Wiki" recipe',
    TRUE, CURRENT_TIMESTAMP);

-- === LAB ENTRY (Critical for medical management) ===

INSERT OR IGNORE INTO xp_earning_rules VALUES
(5, 'lab_value_entered', 50,
    NULL, NULL, NULL,
    FALSE, 20, NULL, 0,
    'lab_entry',
    'Enter lab test results (K+, Na+, Cr, eGFR, HbA1c, etc.)',
    'User enters K+ = 4.2 mEq/L from lab report',
    TRUE, CURRENT_TIMESTAMP);

INSERT OR IGNORE INTO xp_earning_rules VALUES
(6, 'hba1c_logged', 75,
    NULL, NULL, NULL,
    FALSE, 4, NULL, 0,
    'lab_entry',
    'Enter HbA1c test result (every 3 months typically)',
    'User enters HbA1c = 6.8%',
    TRUE, CURRENT_TIMESTAMP);

INSERT OR IGNORE INTO xp_earning_rules VALUES
(7, 'egfr_logged', 75,
    NULL, NULL, NULL,
    FALSE, 4, NULL, 0,
    'lab_entry',
    'Enter eGFR test result for kidney function tracking',
    'User enters eGFR = 52 mL/min',
    TRUE, CURRENT_TIMESTAMP);

-- === BIOMETRIC LOGGING (Daily tracking) ===

INSERT OR IGNORE INTO xp_earning_rules VALUES
(8, 'fbs_logged', 15,
    '1.0 + (consecutive_days * 0.03)',  -- Up to 2.0x at 33 consecutive days
    NULL, NULL,
    FALSE, 1, NULL, 0,
    'biometric',
    'Log fasting blood sugar reading',
    'User enters FBS = 105 mg/dL',
    TRUE, CURRENT_TIMESTAMP);

INSERT OR IGNORE INTO xp_earning_rules VALUES
(9, 'rbs_logged', 10,
    '1.0 + (daily_count * 0.1)',  -- Bonus for multiple readings per day
    NULL, NULL,
    FALSE, 5, NULL, 0,
    'biometric',
    'Log random blood sugar reading',
    'User enters RBS = 145 mg/dL (2 hours post-meal)',
    TRUE, CURRENT_TIMESTAMP);

INSERT OR IGNORE INTO xp_earning_rules VALUES
(10, 'bp_logged', 15,
    '1.0 + (consecutive_days * 0.03)',
    NULL, NULL,
    FALSE, 3, NULL, 0,
    'biometric',
    'Log blood pressure reading',
    'User enters BP = 128/82 mmHg',
    TRUE, CURRENT_TIMESTAMP);

INSERT OR IGNORE INTO xp_earning_rules VALUES
(11, 'weight_logged', 10,
    NULL, NULL, NULL,
    FALSE, 1, NULL, 24,
    'biometric',
    'Log body weight measurement',
    'User enters weight = 68kg',
    TRUE, CURRENT_TIMESTAMP);

-- === MEDICATION ADHERENCE ===

INSERT OR IGNORE INTO xp_earning_rules VALUES
(12, 'medication_taken_confirmed', 10,
    '1.0 + (adherence_pct * 0.01)',  -- Up to 2.0x for 100% adherence
    NULL, NULL,
    FALSE, 20, NULL, 0,
    'medication',
    'Confirm medication intake',
    'User confirms "Metformin 500mg taken at 08:00"',
    TRUE, CURRENT_TIMESTAMP);

INSERT OR IGNORE INTO xp_earning_rules VALUES
(13, 'medication_schedule_completed', 50,
    NULL, NULL, NULL,
    FALSE, 1, NULL, 0,
    'medication',
    'Complete all scheduled medications for the day',
    'User took all 4 scheduled medications today',
    TRUE, CURRENT_TIMESTAMP);

-- === SOCIAL & COMMUNITY ===

INSERT OR IGNORE INTO xp_earning_rules VALUES
(14, 'recipe_created', 75,
    NULL,
    '1.0 + (rating / 5)',  -- Up to 2.0x for 5-star recipe
    NULL,
    TRUE, 5, 20, 24,
    'social',
    'Create and share recipe with community',
    'User submits "My Grandmother\'s Sukuma Wiki Stew" recipe',
    TRUE, CURRENT_TIMESTAMP);

INSERT OR IGNORE INTO xp_earning_rules VALUES
(15, 'recipe_reviewed', 15,
    NULL, NULL, NULL,
    FALSE, 10, NULL, 1,
    'social',
    'Write helpful review of a recipe',
    'User reviews recipe with detailed feedback',
    TRUE, CURRENT_TIMESTAMP);

INSERT OR IGNORE INTO xp_earning_rules VALUES
(16, 'food_submitted', 50,
    NULL, NULL, NULL,
    TRUE, 3, 10, 24,
    'social',
    'Submit new food to database (pending approval)',
    'User submits "Matembele" (local sweet potato leaves)',
    TRUE, CURRENT_TIMESTAMP);

INSERT OR IGNORE INTO xp_earning_rules VALUES
(17, 'community_post', 20,
    NULL, NULL, NULL,
    FALSE, 5, NULL, 2,
    'social',
    'Create community post (health tip, question, success story)',
    'User posts "How I reduced my HbA1c by 2% in 3 months"',
    TRUE, CURRENT_TIMESTAMP);

INSERT OR IGNORE INTO xp_earning_rules VALUES
(18, 'helpful_comment', 10,
    NULL, NULL, NULL,
    FALSE, 20, NULL, 0,
    'social',
    'Leave helpful comment on community post',
    'User provides detailed answer to another user\'s question',
    TRUE, CURRENT_TIMESTAMP);

-- === ACHIEVEMENTS (Major milestones) ===

INSERT OR IGNORE INTO xp_earning_rules VALUES
(19, 'hba1c_improved_0_5pct', 200,
    NULL, NULL, NULL,
    FALSE, NULL, NULL, NULL,
    'achievement',
    'HbA1c drops by 0.5% or more',
    'HbA1c drops from 8.2% to 7.7% → 200 XP',
    TRUE, CURRENT_TIMESTAMP);

INSERT OR IGNORE INTO xp_earning_rules VALUES
(20, 'hba1c_improved_1_0pct', 500,
    NULL, NULL, NULL,
    FALSE, NULL, NULL, NULL,
    'achievement',
    'HbA1c drops by 1.0% or more (RARE)',
    'HbA1c drops from 8.5% to 7.5% → 500 XP',
    TRUE, CURRENT_TIMESTAMP);

INSERT OR IGNORE INTO xp_earning_rules VALUES
(21, 'hba1c_improved_2_0pct', 1000,
    NULL, NULL, NULL,
    FALSE, NULL, NULL, NULL,
    'achievement',
    'HbA1c drops by 2.0% or more (EPIC)',
    'HbA1c drops from 9.0% to 7.0% → 1000 XP',
    TRUE, CURRENT_TIMESTAMP);

INSERT OR IGNORE INTO xp_earning_rules VALUES
(22, 'potassium_normalized', 150,
    NULL, NULL, NULL,
    FALSE, NULL, NULL, NULL,
    'achievement',
    'Potassium returns to normal range (3.5-5.0 mEq/L)',
    'K+ was 5.8, now 4.5 → 150 XP',
    TRUE, CURRENT_TIMESTAMP);

INSERT OR IGNORE INTO xp_earning_rules VALUES
(23, 'bp_controlled_7days', 100,
    NULL, NULL, NULL,
    FALSE, NULL, NULL, NULL,
    'achievement',
    'Blood pressure in target range (<130/80) for 7 consecutive days',
    '7 days with BP <130/80 → 100 XP',
    TRUE, CURRENT_TIMESTAMP);

INSERT OR IGNORE INTO xp_earning_rules VALUES
(24, 'bp_controlled_30days', 500,
    NULL, NULL, NULL,
    FALSE, NULL, NULL, NULL,
    'achievement',
    'Blood pressure controlled for 30 consecutive days (RARE)',
    '30 days with BP <130/80 → 500 XP',
    TRUE, CURRENT_TIMESTAMP);

INSERT OR IGNORE INTO xp_earning_rules VALUES
(25, 'weight_goal_reached', 150,
    NULL, NULL, NULL,
    FALSE, NULL, NULL, NULL,
    'achievement',
    'Reach weight loss or weight gain goal',
    'Lost 5kg as planned → 150 XP',
    TRUE, CURRENT_TIMESTAMP);

INSERT OR IGNORE INTO xp_earning_rules VALUES
(26, 'meal_logging_streak_7days', 100,
    NULL, NULL, NULL,
    FALSE, NULL, NULL, NULL,
    'achievement',
    '7-day meal logging streak',
    'Logged meals for 7 consecutive days → 100 XP',
    TRUE, CURRENT_TIMESTAMP);

INSERT OR IGNORE INTO xp_earning_rules VALUES
(27, 'meal_logging_streak_30days', 500,
    NULL, NULL, NULL,
    FALSE, NULL, NULL, NULL,
    'achievement',
    '30-day meal logging streak (RARE)',
    'Logged meals for 30 consecutive days → 500 XP',
    TRUE, CURRENT_TIMESTAMP);

INSERT OR IGNORE INTO xp_earning_rules VALUES
(28, 'medication_adherence_100pct_30days', 400,
    NULL, NULL, NULL,
    FALSE, NULL, NULL, NULL,
    'achievement',
    '100% medication adherence for 30 days',
    'Took all medications on time for 30 days → 400 XP',
    TRUE, CURRENT_TIMESTAMP);

-- === COMPETITION ===

INSERT OR IGNORE INTO xp_earning_rules VALUES
(29, 'competition_participated', 25,
    NULL, NULL, NULL,
    FALSE, NULL, NULL, NULL,
    'competition',
    'Participate in a leaderboard competition',
    'User joins "Best Meal Logger This Week" competition',
    TRUE, CURRENT_TIMESTAMP);

INSERT OR IGNORE INTO xp_earning_rules VALUES
(30, 'competition_top10', 100,
    NULL, NULL, 'rank_based',  -- More XP for higher rank
    FALSE, NULL, NULL, NULL,
    'competition',
    'Finish in top 10 of competition',
    'Ranked #7 in competition → 100 XP',
    TRUE, CURRENT_TIMESTAMP);

INSERT OR IGNORE INTO xp_earning_rules VALUES
(31, 'competition_top3', 300,
    NULL, NULL, 'rank_based',
    FALSE, NULL, NULL, NULL,
    'competition',
    'Finish in top 3 of competition (RARE)',
    'Ranked #2 in competition → 300 XP',
    TRUE, CURRENT_TIMESTAMP);

INSERT OR IGNORE INTO xp_earning_rules VALUES
(32, 'competition_winner', 500,
    NULL, NULL, NULL,
    FALSE, NULL, NULL, NULL,
    'competition',
    'Win a competition (1st place) (EPIC)',
    'Ranked #1 in competition → 500 XP',
    TRUE, CURRENT_TIMESTAMP);


-- ============================================================================
-- USER XP TRANSACTIONS TABLE
-- ============================================================================
-- Audit log of all XP earned by users

CREATE TABLE user_xp_transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    xp_earning_rule_id INTEGER NOT NULL,

    -- Transaction details
    base_xp INTEGER NOT NULL,
    streak_multiplier REAL DEFAULT 1.0,
    quality_multiplier REAL DEFAULT 1.0,
    difficulty_multiplier REAL DEFAULT 1.0,
    total_multiplier REAL DEFAULT 1.0,  -- Product of all multipliers
    total_xp INTEGER NOT NULL,  -- base_xp × total_multiplier

    -- Context (what triggered this XP?)
    related_entity_type VARCHAR(50),  -- meal / lab_result / biometric / medication / post / recipe
    related_entity_id INTEGER,
    description TEXT,

    -- Metadata
    earned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (xp_earning_rule_id) REFERENCES xp_earning_rules(id)
);

CREATE INDEX idx_xp_transactions_user ON user_xp_transactions(user_id, earned_at DESC);
CREATE INDEX idx_xp_transactions_rule ON user_xp_transactions(xp_earning_rule_id, earned_at DESC);


-- ============================================================================
-- XP MULTIPLIER CONTEXT TABLE
-- ============================================================================
-- Store context used to calculate multipliers (for transparency)

CREATE TABLE xp_multiplier_context (
    xp_transaction_id INTEGER PRIMARY KEY,

    -- Streak context
    streak_days INTEGER,
    streak_type VARCHAR(50),  -- meal_logging / medication / biometric

    -- Quality context
    data_quality_score REAL,
    data_completeness_pct REAL,

    -- Difficulty context
    user_condition_severity VARCHAR(20),  -- mild / moderate / severe
    user_condition_count INTEGER,  -- How many conditions does user manage?

    -- Other context
    time_of_day VARCHAR(20),  -- morning / afternoon / evening / night
    day_of_week VARCHAR(20),

    FOREIGN KEY (xp_transaction_id) REFERENCES user_xp_transactions(id)
);


-- ============================================================================
-- DAILY XP SUMMARY TABLE
-- ============================================================================
-- Aggregated XP earned per day per category

CREATE TABLE daily_xp_summary (
    user_id INTEGER NOT NULL,
    date DATE NOT NULL,

    -- XP by category
    meal_logging_xp INTEGER DEFAULT 0,
    lab_entry_xp INTEGER DEFAULT 0,
    biometric_xp INTEGER DEFAULT 0,
    medication_xp INTEGER DEFAULT 0,
    social_xp INTEGER DEFAULT 0,
    achievement_xp INTEGER DEFAULT 0,
    competition_xp INTEGER DEFAULT 0,

    -- Total
    total_xp INTEGER DEFAULT 0,

    -- Metadata
    actions_count INTEGER DEFAULT 0,
    highest_multiplier REAL DEFAULT 1.0,

    computed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id),
    PRIMARY KEY (user_id, date)
);

CREATE INDEX idx_daily_xp_user_date ON daily_xp_summary(user_id, date DESC);


-- ============================================================================
-- USAGE FLOW: XP Awarding
-- ============================================================================

-- EXAMPLE: User logs complete meal
--
-- STEP 1: Identify action
-- action_type = 'meal_logged_complete'
--
-- STEP 2: Query xp_earning_rule
-- SELECT * FROM xp_earning_rules WHERE action_type = 'meal_logged_complete' AND is_active = TRUE
-- → base_xp = 20
-- → streak_multiplier_formula = "1.0 + (streak_days * 0.05)"
-- → quality_multiplier_formula = "1.0 + (data_quality * 0.5)"
--
-- STEP 3: Check rate limits
-- SELECT COUNT(*) FROM user_xp_transactions
-- WHERE user_id = 123 AND xp_earning_rule_id = 1 AND DATE(earned_at) = CURRENT_DATE
-- → count = 3 (max_per_day = 10, OK to proceed)
--
-- STEP 4: Calculate multipliers
-- - Streak: User has 5-day meal logging streak → 1.0 + (5 * 0.05) = 1.25x
-- - Quality: Meal has data_quality_score = 0.9 → 1.0 + (0.9 * 0.5) = 1.45x
-- - Total multiplier: 1.25 × 1.45 = 1.8125x
--
-- STEP 5: Calculate total XP
-- total_xp = 20 × 1.8125 = 36.25 → ROUND to 36 XP
--
-- STEP 6: Award XP
-- INSERT OR IGNORE INTO user_xp_transactions (user_id, xp_earning_rule_id, base_xp, streak_multiplier, quality_multiplier, total_multiplier, total_xp, related_entity_type, related_entity_id, description)
-- VALUES (123, 1, 20, 1.25, 1.45, 1.8125, 36, 'meal', 456, 'Logged breakfast with complete data');
--
-- UPDATE avatar_stats
-- SET meal_logging_xp = meal_logging_xp + 36,
--     total_xp_earned = total_xp_earned + 36
-- WHERE user_id = 123;
--
-- STEP 7: Store context
-- INSERT OR IGNORE INTO xp_multiplier_context (xp_transaction_id, streak_days, streak_type, data_quality_score)
-- VALUES (xp_transaction_id, 5, 'meal_logging', 0.9);
--
-- STEP 8: Check for level up
-- IF total_xp_earned >= xp_to_next_level:
--   - level++
--   - Display: "🎉 Level Up! You're now level {level}!"
--   - Check for evolution eligibility


-- ============================================================================
-- XP TO LEVEL FORMULA
-- ============================================================================
-- Exponential curve to keep progression challenging but achievable

-- Level 1→2: 100 XP
-- Level 2→3: 100 × 2^1.5 = 283 XP
-- Level 3→4: 100 × 3^1.5 = 520 XP
-- Level 4→5: 100 × 4^1.5 = 800 XP
-- Level 5→10: Continues exponentially
-- Level 10→11: 100 × 10^1.5 = 3,162 XP
-- Level 20→21: 100 × 20^1.5 = 8,944 XP

-- Formula: xp_required = 100 × level^1.5

-- Cumulative XP to reach level:
-- Level 5: ~2,000 XP total
-- Level 10: ~20,000 XP total
-- Level 20: ~180,000 XP total
-- Level 35 (Champion stage): ~1,000,000 XP total

-- Daily XP estimation (engaged user):
-- - 3 meals logged with portions: 3 × 30 = 90 XP
-- - 1 FBS logged: 15 XP
-- - 3 BP readings: 3 × 15 = 45 XP
-- - All medications taken: 50 XP
-- - 1 community interaction: 10 XP
-- Total: ~210 XP/day baseline
-- With streaks/multipliers: ~300-400 XP/day
--
-- Time to reach stages:
-- - Stage 2 (Level 5): ~1 week
-- - Stage 3 (Level 10): ~2 months
-- - Stage 4 (Level 20): ~1 year
-- - Stage 5 (Level 35): ~3+ years (requires sustained excellence)
