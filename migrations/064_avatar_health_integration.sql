-- Migration 064: Avatar Health Integration
-- Links avatar evolution to ALL health metrics (labs, adherence, competition, biometrics)
-- Visible avatar changes motivate healthy behaviors and prepare users for Vuralis
-- Part of Avatar-Health Integration (Phase 3)

-- ============================================================================
-- ENHANCE AVATAR_STATS TABLE
-- ============================================================================
-- Add XP tracking by source (health, adherence, competition, biometrics)

ALTER TABLE avatar_stats ADD COLUMN health_based_xp INTEGER DEFAULT 0;
ALTER TABLE avatar_stats ADD COLUMN adherence_based_xp INTEGER DEFAULT 0;
ALTER TABLE avatar_stats ADD COLUMN competition_based_xp INTEGER DEFAULT 0;
ALTER TABLE avatar_stats ADD COLUMN biometric_based_xp INTEGER DEFAULT 0;
ALTER TABLE avatar_stats ADD COLUMN social_based_xp INTEGER DEFAULT 0;

-- XP to level formula tracking
ALTER TABLE avatar_stats ADD COLUMN xp_to_next_level INTEGER DEFAULT 100;
ALTER TABLE avatar_stats ADD COLUMN total_xp_earned INTEGER DEFAULT 0;

-- Evolution stage
ALTER TABLE avatar_stats ADD COLUMN evolution_stage INTEGER DEFAULT 1;
ALTER TABLE avatar_stats ADD COLUMN evolution_stage_name VARCHAR(50) DEFAULT 'Beginner';

-- Last evolution date (for celebration tracking)
ALTER TABLE avatar_stats ADD COLUMN last_level_up_at TIMESTAMP;
ALTER TABLE avatar_stats ADD COLUMN last_evolution_at TIMESTAMP;

CREATE INDEX idx_avatar_stats_user ON avatar_stats(user_id);
CREATE INDEX idx_avatar_stats_level ON avatar_stats(level DESC);
CREATE INDEX idx_avatar_stats_stage ON avatar_stats(evolution_stage DESC);


-- ============================================================================
-- AVATAR EVOLUTION STAGES TABLE
-- ============================================================================
-- Defines 5 stages of avatar evolution based on sustained health improvements
-- Not just XP - requires REAL health metrics improvements

CREATE TABLE avatar_evolution_stages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    stage_number INTEGER NOT NULL UNIQUE,
    stage_name VARCHAR(50) NOT NULL UNIQUE,
    min_level INTEGER NOT NULL,

    -- Health requirements (days with metrics in target range)
    min_hba1c_control_days INTEGER DEFAULT 0,  -- Days with HbA1c <7% (diabetics only)
    min_bp_control_days INTEGER DEFAULT 0,  -- Days with BP <130/80
    min_meal_logging_streak INTEGER DEFAULT 0,  -- Consecutive days logging ≥2 meals
    min_medication_adherence_pct REAL DEFAULT 0,  -- Overall adherence % since diagnosis
    min_lab_improvements INTEGER DEFAULT 0,  -- Number of lab metrics improved

    -- Engagement requirements
    min_competitions_participated INTEGER DEFAULT 0,
    min_recipes_tried INTEGER DEFAULT 0,
    min_community_interactions INTEGER DEFAULT 0,

    -- Visual changes (JSON describing appearance updates)
    avatar_appearance_json TEXT,
    cosmetic_unlocks TEXT,  -- JSON array of cosmetic IDs unlocked at this stage

    -- Abilities (JSON array of features unlocked)
    special_abilities_json TEXT,

    -- Messaging
    description TEXT,
    congratulations_message TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_evolution_stages_number ON avatar_evolution_stages(stage_number);


-- ============================================================================
-- SEED DATA: Avatar Evolution Stages
-- ============================================================================

-- STAGE 1: BEGINNER (Starting point)
INSERT OR IGNORE INTO avatar_evolution_stages VALUES
(1, 1, 'Beginner', 1,
    0, 0, 0, 0, 0,
    0, 0, 0,
    '{"skin_tone": "pale", "physique": "thin", "energy": "low", "glow": 0}',
    '[]',
    '["basic_meal_log", "view_nutrition"]',
    'Starting your health journey. Every expert was once a beginner.',
    '🎉 Welcome to Vurafya! Your health journey begins now. Let''s take the first step together.',
    CURRENT_TIMESTAMP);

-- STAGE 2: COMMITTED (Showing consistency)
INSERT OR IGNORE INTO avatar_evolution_stages VALUES
(2, 2, 'Committed', 5,
    7, 7, 7, 60, 0,
    0, 3, 5,
    '{"skin_tone": "healthy", "physique": "normal", "energy": "moderate", "glow": 1}',
    '[10, 11, 12]',  -- Basic cosmetics unlocked
    '["meal_log", "basic_analysis", "recipe_save"]',
    'You''re showing up consistently! Your avatar reflects your dedication.',
    '🎉 EVOLUTION! You''ve proven you''re COMMITTED. Your avatar now looks healthier - just like you! Keep it up!',
    CURRENT_TIMESTAMP);

-- STAGE 3: IMPROVING (Measurable health gains)
INSERT OR IGNORE INTO avatar_evolution_stages VALUES
(3, 3, 'Improving', 10,
    30, 30, 30, 75, 2,
    1, 5, 10,
    '{"skin_tone": "vibrant", "physique": "fit", "energy": "high", "glow": 2}',
    '[20, 21, 22, 23, 24]',  -- More cosmetics
    '["meal_log", "analysis", "predictions", "compare_foods"]',
    'Real health improvements showing! Your lab values are moving in the right direction.',
    '🎉 MAJOR EVOLUTION! You''re IMPROVING! Your lab results show it, your avatar shows it, and you FEEL it. This is amazing progress!',
    CURRENT_TIMESTAMP);

-- STAGE 4: THRIVING (Sustained optimal health)
INSERT OR IGNORE INTO avatar_evolution_stages VALUES
(4, 4, 'Thriving', 20,
    90, 90, 60, 85, 4,
    3, 10, 20,
    '{"skin_tone": "radiant", "physique": "athletic", "energy": "excellent", "glow": 3}',
    '[30, 31, 32, 33, 34, 35, 36]',  -- Premium cosmetics
    '["advanced_analysis", "coaching", "meal_planning"]',
    'You''ve achieved optimal health! Sustaining these results is mastery.',
    '🎉 INCREDIBLE EVOLUTION! You''re THRIVING! 90 days of controlled labs, excellent adherence. You''ve mastered health management!',
    CURRENT_TIMESTAMP);

-- STAGE 5: CHAMPION (Health excellence, inspiring others)
INSERT OR IGNORE INTO avatar_evolution_stages VALUES
(5, 5, 'Champion', 35,
    180, 180, 90, 95, 6,
    5, 20, 50,
    '{"skin_tone": "glowing", "physique": "peak", "energy": "maximum", "glow": 4, "aura": "golden"}',
    '[40, 41, 42, 43, 44, 45, 46, 47, 48]',  -- Exclusive cosmetics
    '["expert_mode", "mentor_others", "custom_plans", "research_contribution"]',
    'You''re a CHAMPION! You''ve inspired others and achieved lasting health transformation. You are now prepared for Vuralis.',
    '🏆 LEGENDARY EVOLUTION! You''re a CHAMPION! 6 months of excellence. You inspire others. You''ve transformed your health. Ready for Vuralis?',
    CURRENT_TIMESTAMP);


-- ============================================================================
-- AVATAR HEALTH MILESTONES TABLE
-- ============================================================================
-- Track significant health achievements that earn XP and trigger avatar changes
-- Links real health data to avatar progression

CREATE TABLE avatar_health_milestones (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,

    -- Milestone identification
    milestone_type VARCHAR(50) NOT NULL,  -- lab_improvement / adherence_streak / biometric_goal / competition_win
    milestone_name VARCHAR(100) NOT NULL,

    -- Achievement details
    achieved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metric_name VARCHAR(50),  -- hba1c / bp_systolic / potassium / weight
    baseline_value REAL,  -- Starting value
    achieved_value REAL,  -- Current value
    improvement_pct REAL,  -- Percentage improvement
    improvement_direction VARCHAR(20),  -- decreasing_good / increasing_good

    -- Rewards
    xp_awarded INTEGER NOT NULL,
    afya_points_awarded INTEGER DEFAULT 0,
    cosmetic_unlocked INTEGER,  -- cosmetic_id from avatar_cosmetics table
    evolution_stage_unlocked INTEGER,  -- Did this milestone trigger evolution?

    -- Celebration
    is_public BOOLEAN DEFAULT TRUE,  -- Show in community feed?
    celebration_shown BOOLEAN DEFAULT FALSE,
    celebration_message TEXT,

    -- Metadata
    milestone_rarity VARCHAR(20),  -- common / rare / epic / legendary

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (cosmetic_unlocked) REFERENCES avatar_cosmetics(id),
    FOREIGN KEY (evolution_stage_unlocked) REFERENCES avatar_evolution_stages(id)
);

CREATE INDEX idx_milestones_user ON avatar_health_milestones(user_id, achieved_at DESC);
CREATE INDEX idx_milestones_type ON avatar_health_milestones(milestone_type, achieved_at DESC);
CREATE INDEX idx_milestones_public ON avatar_health_milestones(is_public, achieved_at DESC);


-- ============================================================================
-- SEED DATA: Milestone Definitions
-- ============================================================================

-- NOTE: These are templates - actual milestones created dynamically when user achieves them

-- LAB IMPROVEMENT MILESTONES:
-- - "HbA1c drops 0.5%" → 200 XP
-- - "HbA1c drops 1.0%" → 500 XP (rare)
-- - "HbA1c drops 2.0%" → 1000 XP (epic)
-- - "Potassium normalized" → 150 XP
-- - "eGFR improved 5+ points" → 300 XP (CKD reversal, rare)

-- ADHERENCE MILESTONES:
-- - "7-day meal logging streak" → 100 XP
-- - "30-day meal logging streak" → 500 XP (rare)
-- - "90-day meal logging streak" → 1500 XP (epic)
-- - "100% medication adherence for 30 days" → 400 XP
-- - "100% medication adherence for 90 days" → 1500 XP (epic)

-- BIOMETRIC MILESTONES:
-- - "Weight loss: 5kg" → 250 XP
-- - "Weight loss: 10kg" → 750 XP (rare)
-- - "BP in target range 7 days" → 100 XP
-- - "BP in target range 30 days" → 500 XP (rare)

-- COMPETITION MILESTONES:
-- - "Top 10 finish" → 100 XP
-- - "Top 3 finish" → 300 XP (rare)
-- - "1st place" → 500 XP (epic)


-- ============================================================================
-- AVATAR EVOLUTION PROGRESS TABLE
-- ============================================================================
-- Track user's progress toward next evolution stage

CREATE TABLE avatar_evolution_progress (
    user_id INTEGER PRIMARY KEY,
    current_stage INTEGER NOT NULL DEFAULT 1,
    next_stage INTEGER,

    -- Progress metrics (current counts toward next stage)
    hba1c_control_days_count INTEGER DEFAULT 0,
    bp_control_days_count INTEGER DEFAULT 0,
    meal_logging_streak_days INTEGER DEFAULT 0,
    medication_adherence_pct REAL DEFAULT 0,
    lab_improvements_count INTEGER DEFAULT 0,
    competitions_participated_count INTEGER DEFAULT 0,
    recipes_tried_count INTEGER DEFAULT 0,
    community_interactions_count INTEGER DEFAULT 0,

    -- Progress percentages (calculated)
    hba1c_progress_pct REAL DEFAULT 0,
    bp_progress_pct REAL DEFAULT 0,
    meal_logging_progress_pct REAL DEFAULT 0,
    adherence_progress_pct REAL DEFAULT 0,
    overall_progress_pct REAL DEFAULT 0,

    -- Status
    ready_to_evolve BOOLEAN DEFAULT FALSE,
    evolution_blocked_reason TEXT,  -- Why can't they evolve yet?

    -- Metadata
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (current_stage) REFERENCES avatar_evolution_stages(stage_number),
    FOREIGN KEY (next_stage) REFERENCES avatar_evolution_stages(stage_number)
);

CREATE INDEX idx_evolution_progress_ready ON avatar_evolution_progress(ready_to_evolve, overall_progress_pct DESC);


-- ============================================================================
-- AVATAR APPEARANCE HISTORY TABLE
-- ============================================================================
-- Track visual changes to avatar over time (for user to see transformation)

CREATE TABLE avatar_appearance_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,

    -- Appearance snapshot (JSON)
    appearance_json TEXT NOT NULL,
    evolution_stage INTEGER NOT NULL,
    level INTEGER NOT NULL,

    -- Trigger
    change_reason VARCHAR(100),  -- level_up / evolution / cosmetic_applied / health_milestone
    milestone_id INTEGER,

    -- Screenshot/visualization (optional)
    avatar_image_url VARCHAR(500),

    -- Metadata
    snapshot_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (evolution_stage) REFERENCES avatar_evolution_stages(stage_number),
    FOREIGN KEY (milestone_id) REFERENCES avatar_health_milestones(id)
);

CREATE INDEX idx_appearance_history_user ON avatar_appearance_history(user_id, snapshot_at DESC);


-- ============================================================================
-- USAGE FLOW: Avatar Evolution
-- ============================================================================

-- DAILY HEALTH CHECK (Run at midnight):
--
-- STEP 1: Update daily metrics
-- - Check if user logged ≥2 meals today → meal_logging_streak_days++
-- - Check if user took all medications → Update medication_adherence_pct
-- - Check if BP was in target today → bp_control_days_count++
-- - Check if HbA1c is in control (from most recent test) → hba1c_control_days_count++
--
-- STEP 2: Check for milestones
-- IF meal_logging_streak_days = 7:
--   - INSERT OR IGNORE INTO avatar_health_milestones (milestone_type='adherence_streak', milestone_name='7-day meal logging streak', xp_awarded=100)
--   - UPDATE avatar_stats SET adherence_based_xp += 100, total_xp_earned += 100
--
-- IF hba1c improved ≥0.5% since last test:
--   - INSERT OR IGNORE INTO avatar_health_milestones (milestone_type='lab_improvement', milestone_name='HbA1c drops 0.5%', xp_awarded=200, baseline_value=8.2, achieved_value=7.7, improvement_pct=6.1)
--   - UPDATE avatar_stats SET health_based_xp += 200, total_xp_earned += 200
--
-- STEP 3: Check for level up
-- IF total_xp_earned >= xp_to_next_level:
--   - level++
--   - xp_to_next_level = calculate_xp_for_next_level(level)  -- Exponential: 100 × level^1.5
--   - last_level_up_at = NOW()
--   - Display: "🎉 Level Up! You're now level {level}!"
--
-- STEP 4: Check for evolution
-- - Query avatar_evolution_stages WHERE stage_number = current_stage + 1
-- - Check if user meets ALL requirements:
--   * min_level ✓
--   * min_hba1c_control_days ✓
--   * min_bp_control_days ✓
--   * min_meal_logging_streak ✓
--   * min_medication_adherence_pct ✓
--   * min_lab_improvements ✓
-- - IF all met:
--     * evolution_stage++
--     * evolution_stage_name = next_stage.stage_name
--     * last_evolution_at = NOW()
--     * INSERT OR IGNORE INTO avatar_health_milestones (milestone_type='evolution', evolution_stage_unlocked=new_stage, xp_awarded=1000)
--     * Unlock cosmetics from cosmetic_unlocks JSON
--     * Display EPIC celebration animation
--     * Send notification: "🏆 EVOLUTION! You've reached {stage_name}!"
--
-- STEP 5: Update appearance
-- - Parse avatar_appearance_json from evolution_stages table
-- - Apply changes to avatar visual (skin_tone, physique, energy, glow)
-- - INSERT OR IGNORE INTO avatar_appearance_history
-- - Notify user of visual change: "Your avatar looks healthier!"


-- ============================================================================
-- EXAMPLE: User Journey
-- ============================================================================

-- DAY 1: User starts
-- - Level 1, Stage 1 (Beginner)
-- - Avatar: Pale skin, thin physique, low energy
-- - 0 XP

-- WEEK 1: User logs meals daily
-- - Day 7 milestone: "7-day meal logging streak" → +100 XP
-- - Level 2 achieved!
-- - Avatar: Slight glow appears

-- WEEK 2: First HbA1c test improvement
-- - HbA1c drops from 8.2% to 7.7% (0.5% improvement)
-- - Milestone: "HbA1c improved 0.5%" → +200 XP
-- - Level 3 achieved!
-- - Total: 7 days HbA1c control, 7 days BP control, 14 days meal logging

-- MONTH 1: Checking evolution progress
-- - Level 5 achieved
-- - Stage 1 → Stage 2 requirements:
--   * min_level: 5 ✅
--   * min_hba1c_control_days: 7 ✅ (have 7)
--   * min_bp_control_days: 7 ✅ (have 12)
--   * min_meal_logging_streak: 7 ✅ (have 14)
--   * min_medication_adherence_pct: 60 ✅ (have 85%)
-- - 🎉 EVOLUTION TO STAGE 2: COMMITTED!
-- - Avatar: Healthy skin tone, normal physique, moderate energy, +1 glow
-- - Unlocked: Basic cosmetics [10, 11, 12]
-- - Celebration message shown in app
-- - Friends notified: "Sarah evolved to Committed stage!"

-- MONTH 3: Sustained improvement
-- - Level 12
-- - Stage 2 → Stage 3 requirements:
--   * min_level: 10 ✅ (have 12)
--   * min_hba1c_control_days: 30 ✅ (have 45)
--   * min_bp_control_days: 30 ✅ (have 50)
--   * min_meal_logging_streak: 30 ✅ (have 60)
--   * min_medication_adherence_pct: 75 ✅ (have 88%)
--   * min_lab_improvements: 2 ✅ (HbA1c improved, K+ normalized)
-- - 🎉 EVOLUTION TO STAGE 3: IMPROVING!
-- - Avatar: Vibrant skin, fit physique, high energy, +2 glow
-- - Unlocked: More cosmetics [20-24]
-- - New abilities: Predictions, Compare Foods

-- MONTH 6+: Health mastery
-- - Eventually reaches Stage 4 (Thriving) and Stage 5 (Champion)
-- - Avatar: Glowing skin, peak physique, golden aura
-- - Becomes mentor to other users
-- - Ready for Vuralis integration
