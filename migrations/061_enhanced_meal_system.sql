-- Migration 061: Enhanced Meal System
-- Enables three-way meal logging: recipes + custom meals + component-by-component
-- Adds meal logging enforcement for clinical safety
-- Part of Meal-First Architecture (Phase 2)

-- ============================================================================
-- ENHANCE MEALS TABLE
-- ============================================================================
-- Add columns to support flexible meal logging and cooking context

ALTER TABLE meals ADD COLUMN meal_source VARCHAR(50) DEFAULT 'component_assembly';
ALTER TABLE meals ADD COLUMN recipe_id INTEGER;
ALTER TABLE meals ADD COLUMN portion_size_pct REAL DEFAULT 100.0;
ALTER TABLE meals ADD COLUMN cooking_method_id INTEGER;
ALTER TABLE meals ADD COLUMN preparation_notes TEXT;

-- Add foreign key constraints
-- (Assuming meals table already has user_id, meal_type, meal_name, meal_time columns)
-- ALTER TABLE meals ADD FOREIGN KEY (recipe_id) REFERENCES recipes(id);
-- ALTER TABLE meals ADD FOREIGN KEY (cooking_method_id) REFERENCES cooking_methods(id);

-- Add check constraint for meal_source
-- ALTER TABLE meals ADD CHECK (meal_source IN ('recipe', 'custom', 'component_assembly'));

-- Create indexes for query performance
CREATE INDEX idx_meals_user_date ON meals(user_id, meal_time);
CREATE INDEX idx_meals_recipe ON meals(recipe_id) WHERE recipe_id IS NOT NULL;
CREATE INDEX idx_meals_source ON meals(meal_source);


-- ============================================================================
-- MEAL LOGGING REQUIREMENTS TABLE
-- ============================================================================
-- Condition-specific requirements for meal logging frequency and detail
-- Critical for clinical safety: Can't recommend foods if we don't know what they already ate

CREATE TABLE meal_logging_requirements (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    condition VARCHAR(50) NOT NULL,  -- CKD / diabetes / hypertension / all

    -- Frequency requirements
    min_meals_per_day INTEGER DEFAULT 2,
    min_meal_gap_hours INTEGER DEFAULT 3,  -- Minimum time between meals
    max_meal_gap_hours INTEGER DEFAULT 6,  -- Maximum time between meals (warn if exceeded)

    -- Data completeness requirements
    require_timing BOOLEAN DEFAULT TRUE,  -- Must log meal_time (not just "lunch")
    require_portions BOOLEAN DEFAULT TRUE,  -- Must specify quantities in meal_components
    require_cooking_method BOOLEAN DEFAULT FALSE,  -- Must specify how food was prepared
    require_all_components BOOLEAN DEFAULT FALSE,  -- Must log all foods in meal (not just main items)

    -- Specific meal requirements
    warn_if_no_breakfast BOOLEAN DEFAULT TRUE,
    warn_if_no_lunch BOOLEAN DEFAULT FALSE,
    warn_if_no_dinner BOOLEAN DEFAULT TRUE,

    -- Enforcement level
    enforcement_level VARCHAR(20) DEFAULT 'soft',  -- soft / hard / critical
    block_recommendations_if_noncompliant BOOLEAN DEFAULT FALSE,  -- Block AI recommendations if not logging?

    -- Grace periods
    grace_period_days INTEGER DEFAULT 7,  -- Allow learning period for new users
    reminder_frequency_hours INTEGER DEFAULT 8,  -- How often to remind user

    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    set_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    set_by INTEGER,  -- Medical staff who prescribed this requirement

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (set_by) REFERENCES medical_staff(id),

    CHECK (enforcement_level IN ('soft', 'hard', 'critical')),
    UNIQUE(user_id, condition, is_active)
);

CREATE INDEX idx_meal_logging_reqs_user ON meal_logging_requirements(user_id, is_active);
CREATE INDEX idx_meal_logging_reqs_condition ON meal_logging_requirements(condition);


-- ============================================================================
-- SEED DATA: Default Meal Logging Requirements by Condition
-- ============================================================================

-- CKD Patients (Critical - missed meals = dangerous K+ recommendations)
-- Note: These will be created when users are assigned CKD condition via user_conditions table
-- Uncomment and modify the query below when users exist with CKD diagnosis:
-- INSERT OR IGNORE INTO meal_logging_requirements
-- (user_id, condition, min_meals_per_day, max_meal_gap_hours, require_timing, require_portions, require_cooking_method, warn_if_no_breakfast, warn_if_no_dinner, enforcement_level, block_recommendations_if_noncompliant, reminder_frequency_hours, is_active)
-- SELECT DISTINCT
--     uc.user_id AS user_id,
--     'CKD' AS condition,
--     2 AS min_meals_per_day,
--     8 AS max_meal_gap_hours,
--     TRUE AS require_timing,
--     TRUE AS require_portions,
--     FALSE AS require_cooking_method,
--     TRUE AS warn_if_no_breakfast,
--     TRUE AS warn_if_no_dinner,
--     'hard' AS enforcement_level,
--     TRUE AS block_recommendations_if_noncompliant,
--     6 AS reminder_frequency_hours,
--     TRUE AS is_active
-- FROM user_conditions uc
-- JOIN medical_conditions mc ON uc.condition_id = mc.id
-- WHERE mc.name LIKE '%CKD%' OR mc.name LIKE '%Chronic Kidney Disease%';

-- Diabetes Patients (Critical - need meal context for blood sugar interpretation)
-- Note: These will be created when users are assigned Diabetes condition via user_conditions table
-- Uncomment and modify the query below when users exist with Diabetes diagnosis:
-- INSERT OR IGNORE INTO meal_logging_requirements
-- (user_id, condition, min_meals_per_day, max_meal_gap_hours, require_timing, require_portions, warn_if_no_breakfast, warn_if_no_lunch, warn_if_no_dinner, enforcement_level, block_recommendations_if_noncompliant, reminder_frequency_hours)
-- SELECT DISTINCT
--     uc.user_id AS user_id,
--     'Diabetes' AS condition,
--     3 AS min_meals_per_day,
--     6 AS max_meal_gap_hours,
--     TRUE AS require_timing,
--     TRUE AS require_portions,
--     TRUE AS warn_if_no_breakfast,
--     FALSE AS warn_if_no_lunch,
--     TRUE AS warn_if_no_dinner,
--     'hard' AS enforcement_level,
--     TRUE AS block_recommendations_if_noncompliant,
--     8 AS reminder_frequency_hours
-- FROM user_conditions uc
-- JOIN medical_conditions mc ON uc.condition_id = mc.id
-- WHERE mc.name LIKE '%Diabetes%';


-- ============================================================================
-- MEAL LOGGING COMPLIANCE TABLE
-- ============================================================================
-- Daily tracking of user compliance with meal logging requirements
-- Auto-computed at end of day or on-demand

CREATE TABLE meal_logging_compliance (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    date DATE NOT NULL,

    -- Daily metrics
    meals_logged_count INTEGER DEFAULT 0,
    meals_required_count INTEGER DEFAULT 3,
    compliance_pct REAL,  -- (meals_logged / meals_required) × 100

    -- Gap analysis
    longest_gap_hours REAL,  -- Longest time between consecutive meals
    meal_times_logged TEXT,  -- JSON array: ["07:30", "13:15", "19:45"]
    missing_meal_times TEXT,  -- JSON array: ["breakfast", "dinner"]

    -- Data quality
    meals_with_portions INTEGER DEFAULT 0,  -- How many meals had portion sizes?
    meals_with_timing INTEGER DEFAULT 0,  -- How many had specific times (not just "lunch")?
    meals_with_cooking_method INTEGER DEFAULT 0,

    -- Compliance status
    is_compliant BOOLEAN DEFAULT FALSE,
    warnings_issued INTEGER DEFAULT 0,
    recommendation_block_active BOOLEAN DEFAULT FALSE,  -- Are recommendations blocked due to non-compliance?

    -- Audit
    computed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_warning_at TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id),
    UNIQUE(user_id, date)
);

CREATE INDEX idx_meal_compliance_user_date ON meal_logging_compliance(user_id, date DESC);
CREATE INDEX idx_meal_compliance_status ON meal_logging_compliance(is_compliant, date DESC);


-- ============================================================================
-- MEAL LOGGING WARNINGS TABLE
-- ============================================================================
-- Track when and why warnings were issued

CREATE TABLE meal_logging_warnings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    warning_date DATE NOT NULL,
    warning_type VARCHAR(50) NOT NULL,  -- no_breakfast / large_gap / no_portions / insufficient_meals

    -- Warning details
    warning_message TEXT NOT NULL,
    severity VARCHAR(20) NOT NULL,  -- info / warning / critical

    -- Context
    meals_logged_today INTEGER,
    meals_required INTEGER,
    gap_hours REAL,

    -- User response
    acknowledged BOOLEAN DEFAULT FALSE,
    acknowledged_at TIMESTAMP,
    user_action TEXT,  -- logged_meal / dismissed / ignored

    -- Audit
    issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id),

    CHECK (severity IN ('info', 'warning', 'critical'))
);

CREATE INDEX idx_warnings_user_date ON meal_logging_warnings(user_id, warning_date DESC);
CREATE INDEX idx_warnings_acknowledged ON meal_logging_warnings(acknowledged, issued_at DESC);


-- ============================================================================
-- MEAL PORTION ADJUSTMENTS TABLE
-- ============================================================================
-- Track when users eat non-standard portions
-- Example: "I ate half a plate" → portion_multiplier = 0.5

CREATE TABLE meal_portion_adjustments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    meal_id INTEGER NOT NULL,
    meal_component_id INTEGER,  -- NULL if adjustment applies to whole meal

    -- Portion modifications
    standard_portion_grams REAL,
    actual_portion_grams REAL,
    portion_multiplier REAL,  -- actual / standard

    -- Reason for adjustment
    adjustment_reason VARCHAR(50),  -- patient_preference / appetite_low / cost / availability / religious / cultural
    user_notes TEXT,

    -- Audit
    adjusted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (meal_id) REFERENCES meals(id),
    FOREIGN KEY (meal_component_id) REFERENCES meal_components(id),

    CHECK (portion_multiplier > 0)
);

CREATE INDEX idx_portion_adjustments_meal ON meal_portion_adjustments(meal_id);


-- ============================================================================
-- USAGE FLOW: THREE-WAY MEAL LOGGING
-- ============================================================================

-- METHOD 1: RECIPE-BASED LOGGING
-- User selects recipe: "Ugali with Sukuma Wiki Stew"
-- INSERT OR IGNORE INTO meals (user_id, meal_source, recipe_id, portion_size_pct, meal_time)
-- VALUES (123, 'recipe', 45, 100.0, '2026-04-12 13:30:00');
--
-- Nutrition calculated from recipe_ingredients table
-- If user ate "half portion" → portion_size_pct = 50.0
-- INSERT OR IGNORE INTO meal_portion_adjustments (meal_id, portion_multiplier, adjustment_reason)
-- VALUES (meal_id, 0.5, 'appetite_low');

-- METHOD 2: CUSTOM MEAL LOGGING
-- User creates ad-hoc meal: "Leftovers from yesterday"
-- INSERT OR IGNORE INTO meals (user_id, meal_source, meal_name, meal_time)
-- VALUES (123, 'custom', 'Leftovers', '2026-04-12 19:00:00');
--
-- Then add components:
-- INSERT OR IGNORE INTO meal_components (meal_id, food_id, quantity_grams)
-- VALUES
--   (meal_id, 9, 150),  -- 150g rice
--   (meal_id, 28, 100); -- 100g chicken
--
-- Nutrition calculated from meal_components

-- METHOD 3: COMPONENT-BY-COMPONENT (Most flexible)
-- User logs: "Breakfast: 2 eggs, 1 slice bread, 1 cup tea"
-- INSERT OR IGNORE INTO meals (user_id, meal_source, meal_type, meal_time)
-- VALUES (123, 'component_assembly', 'breakfast', '2026-04-12 07:30:00');
--
-- INSERT OR IGNORE INTO meal_components (meal_id, food_id, quantity_grams)
-- VALUES
--   (meal_id, 28, 100),  -- 2 eggs (~50g each)
--   (meal_id, 8, 30),    -- 1 slice bread
--   (meal_id, 55, 240);  -- 1 cup tea
--
-- Nutrition calculated from sum of components


-- ============================================================================
-- COMPLIANCE CHECKING FLOW (Application Layer)
-- ============================================================================

-- RUN DAILY AT MIDNIGHT (OR ON-DEMAND):
--
-- STEP 1: For each user with active meal_logging_requirements:
--
-- STEP 2: Count meals logged today
-- SELECT COUNT(*) FROM meals
-- WHERE user_id = :user_id
-- AND DATE(meal_time) = CURRENT_DATE
--
-- STEP 3: Check requirements
-- SELECT * FROM meal_logging_requirements
-- WHERE user_id = :user_id AND is_active = TRUE
--
-- STEP 4: Calculate compliance
-- compliance_pct = (meals_logged_count / meals_required_count) × 100
--
-- STEP 5: Check meal gaps
-- SELECT meal_time FROM meals
-- WHERE user_id = :user_id AND DATE(meal_time) = CURRENT_DATE
-- ORDER BY meal_time ASC
-- → Calculate gaps between consecutive meals
-- → longest_gap_hours = MAX(gap)
--
-- STEP 6: Identify missing meals
-- IF no meal between 06:00-10:00 → missing "breakfast"
-- IF no meal between 12:00-14:00 → missing "lunch"
-- IF no meal between 18:00-21:00 → missing "dinner"
--
-- STEP 7: Update meal_logging_compliance table
-- INSERT OR REPLACE INTO meal_logging_compliance (...)
--
-- STEP 8: Issue warnings if needed
-- IF is_compliant = FALSE AND enforcement_level = 'hard':
--   - INSERT OR IGNORE INTO meal_logging_warnings
--   - Send push notification
--   - IF block_recommendations_if_noncompliant = TRUE:
--       * Set recommendation_block_active = TRUE
--       * Display banner: "⚠️ Log meals to receive recommendations"

-- REAL-TIME CHECKING:
-- When user requests food recommendation:
-- 1. Check meal_logging_compliance for today
-- 2. IF recommendation_block_active = TRUE:
--    → Display: "Please log your meals today before we can recommend foods safely."
--    → Prevent showing recommendations that might be dangerous
--
-- Example dangerous scenario prevented:
-- - CKD patient hasn't logged meals today
-- - Lab shows K+ = 5.2 (elevated but not critical)
-- - System would normally recommend LOW-K foods
-- - BUT: What if they already ate 3 bananas this morning and forgot to log?
-- - Recommending more food = potential hyperkalemia crisis
-- - SOLUTION: Block recommendations until meal logging is current

-- NOTIFICATION EXAMPLES:
-- - "⚠️ You haven't logged breakfast yet. Logging meals helps us give you safe recommendations."
-- - "🚨 It's been 8 hours since your last meal. For diabetes management, consistent meal timing is important."
-- - "ℹ️ You've logged 2/3 required meals today. Great job! Don't forget dinner."
