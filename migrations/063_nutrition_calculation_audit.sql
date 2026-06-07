-- Migration 063: Nutrition Calculation Audit
-- Transparent nutrition calculations with raw → cooked adjustments
-- Stores calculation method, data quality, and warnings
-- Final migration of Meal-First Architecture (Phase 2)

-- ============================================================================
-- MEAL NUTRITION CALCULATIONS TABLE
-- ============================================================================
-- Complete audit trail of how nutrition was calculated for each meal
-- Shows raw values → cooking adjustments → final values

CREATE TABLE meal_nutrition_calculations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    meal_id INTEGER NOT NULL UNIQUE,

    -- Calculation metadata
    calculation_method VARCHAR(50) NOT NULL,  -- recipe_based / component_sum / hybrid / estimated
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    calculation_version VARCHAR(20) DEFAULT '1.0',

    -- === RAW NUTRITION (Before Cooking Adjustments) ===
    raw_energy_kcal REAL,
    raw_protein_g REAL,
    raw_carbs_g REAL,
    raw_fat_g REAL,
    raw_fiber_g REAL,
    raw_sugar_g REAL,

    -- Raw micronutrients
    raw_potassium_mg REAL,
    raw_sodium_mg REAL,
    raw_calcium_mg REAL,
    raw_iron_mg REAL,
    raw_magnesium_mg REAL,
    raw_phosphorus_mg REAL,
    raw_zinc_mg REAL,

    -- Raw vitamins
    raw_vitamin_a_mcg REAL,
    raw_vitamin_c_mg REAL,
    raw_vitamin_d_mcg REAL,
    raw_vitamin_e_mg REAL,
    raw_folate_mcg REAL,
    raw_vitamin_b12_mcg REAL,

    -- === ADJUSTED NUTRITION (After Cooking Retention) ===
    adjusted_energy_kcal REAL,
    adjusted_protein_g REAL,
    adjusted_carbs_g REAL,
    adjusted_fat_g REAL,
    adjusted_fiber_g REAL,
    adjusted_sugar_g REAL,

    -- Adjusted micronutrients
    adjusted_potassium_mg REAL,
    adjusted_sodium_mg REAL,
    adjusted_calcium_mg REAL,
    adjusted_iron_mg REAL,
    adjusted_magnesium_mg REAL,
    adjusted_phosphorus_mg REAL,
    adjusted_zinc_mg REAL,

    -- Adjusted vitamins
    adjusted_vitamin_a_mcg REAL,
    adjusted_vitamin_c_mg REAL,
    adjusted_vitamin_d_mcg REAL,
    adjusted_vitamin_e_mg REAL,
    adjusted_folate_mcg REAL,
    adjusted_vitamin_b12_mcg REAL,

    -- === COOKING IMPACT SUMMARY ===
    cooking_method_id INTEGER,
    total_weight_raw_g REAL,
    total_weight_cooked_g REAL,
    weight_yield_factor REAL,  -- cooked / raw
    average_retention_factor REAL,  -- Average of all nutrients

    -- === CLINICAL METRICS ===
    glycemic_load REAL,
    glycemic_load_category VARCHAR(20),  -- low / medium / high
    pral_value REAL,  -- Potential Renal Acid Load (for CKD)
    pral_category VARCHAR(20),  -- alkaline / neutral / acidic
    sodium_potassium_ratio REAL,  -- Important for hypertension

    -- === DATA QUALITY ===
    calculation_warnings TEXT,  -- JSON array of warnings
    data_quality_score REAL,  -- 0.0-1.0 (1.0 = all measured data, <0.5 = heavily estimated)
    missing_nutrients TEXT,  -- JSON array of nutrients that couldn't be calculated
    estimated_nutrients TEXT,  -- JSON array of nutrients that were estimated

    -- === PORTION CONTEXT ===
    number_of_components INTEGER,  -- How many foods in this meal?
    has_custom_portions BOOLEAN DEFAULT FALSE,
    portion_adjustment_applied BOOLEAN DEFAULT FALSE,

    FOREIGN KEY (meal_id) REFERENCES meals(id),
    FOREIGN KEY (cooking_method_id) REFERENCES cooking_methods(id),

    CHECK (data_quality_score BETWEEN 0.0 AND 1.0)
);

CREATE INDEX idx_nutrition_calc_meal ON meal_nutrition_calculations(meal_id);
CREATE INDEX idx_nutrition_calc_quality ON meal_nutrition_calculations(data_quality_score DESC);
CREATE INDEX idx_nutrition_calc_method ON meal_nutrition_calculations(calculation_method);


-- ============================================================================
-- CALCULATION WARNINGS TABLE
-- ============================================================================
-- Detailed warnings issued during nutrition calculation
-- Example: "Vitamin C data missing for Food ID 45"

CREATE TABLE calculation_warnings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    meal_nutrition_calculation_id INTEGER NOT NULL,

    -- Warning details
    warning_type VARCHAR(50) NOT NULL,  -- missing_data / estimated_value / retention_unavailable / portion_unclear
    severity VARCHAR(20) NOT NULL,  -- info / warning / error
    warning_message TEXT NOT NULL,

    -- Context
    affected_nutrient VARCHAR(50),
    affected_food_id INTEGER,
    fallback_method VARCHAR(100),  -- What was done to work around the issue?

    -- Metadata
    issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (meal_nutrition_calculation_id) REFERENCES meal_nutrition_calculations(id),
    FOREIGN KEY (affected_food_id) REFERENCES foods(id),

    CHECK (severity IN ('info', 'warning', 'error'))
);

CREATE INDEX idx_warnings_calculation ON calculation_warnings(meal_nutrition_calculation_id);
CREATE INDEX idx_warnings_severity ON calculation_warnings(severity, issued_at DESC);


-- ============================================================================
-- CALCULATION COMPARISON TABLE
-- ============================================================================
-- Compare calculated values vs user-entered values (if user provides nutrition info)
-- Example: Food label says 250 kcal, our calculation says 310 kcal → 24% difference

CREATE TABLE nutrition_calculation_comparisons (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    meal_id INTEGER NOT NULL,

    -- User-provided values (from food label or manual entry)
    user_provided_calories REAL,
    user_provided_protein_g REAL,
    user_provided_carbs_g REAL,
    user_provided_fat_g REAL,
    user_provided_source VARCHAR(100),  -- food_label / nutritionist / app

    -- Our calculated values
    calculated_calories REAL,
    calculated_protein_g REAL,
    calculated_carbs_g REAL,
    calculated_fat_g REAL,

    -- Comparison
    calories_difference_pct REAL,  -- (calculated - user_provided) / user_provided × 100
    protein_difference_pct REAL,
    carbs_difference_pct REAL,
    fat_difference_pct REAL,

    -- Flags
    large_discrepancy BOOLEAN DEFAULT FALSE,  -- >20% difference
    investigation_needed BOOLEAN DEFAULT FALSE,
    resolution TEXT,  -- What was done to resolve discrepancy?

    -- Metadata
    compared_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (meal_id) REFERENCES meals(id)
);

CREATE INDEX idx_comparisons_meal ON nutrition_calculation_comparisons(meal_id);
CREATE INDEX idx_comparisons_discrepancy ON nutrition_calculation_comparisons(large_discrepancy, compared_at DESC);


-- ============================================================================
-- NUTRIENT CONTRIBUTION BREAKDOWN TABLE
-- ============================================================================
-- Shows which foods contributed what % of each nutrient in a meal
-- Example: "Rice provided 60% of calories, Chicken provided 80% of protein"

CREATE TABLE nutrient_contribution_breakdown (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    meal_id INTEGER NOT NULL,
    food_id INTEGER NOT NULL,

    -- Weight contribution
    food_weight_g REAL,
    total_meal_weight_g REAL,
    weight_contribution_pct REAL,

    -- Nutrient contributions
    energy_contribution_pct REAL,
    protein_contribution_pct REAL,
    carbs_contribution_pct REAL,
    fat_contribution_pct REAL,
    fiber_contribution_pct REAL,
    potassium_contribution_pct REAL,
    sodium_contribution_pct REAL,

    -- Metadata
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (meal_id) REFERENCES meals(id),
    FOREIGN KEY (food_id) REFERENCES foods(id),

    UNIQUE(meal_id, food_id)
);

CREATE INDEX idx_contributions_meal ON nutrient_contribution_breakdown(meal_id);


-- ============================================================================
-- USAGE FLOW: Meal Nutrition Calculation
-- ============================================================================

-- STEP 1: User logs meal
-- - Component-by-component: 200g rice, 100g chicken, 50g vegetables
-- - Recipe-based: "Ugali with Sukuma Wiki" (1 serving)
-- - Custom: "Leftovers from yesterday"

-- STEP 2: Calculate raw nutrition
-- FOR EACH meal_component:
--   - Query food_nutrients WHERE food_id = component.food_id
--   - Calculate: nutrient_amount = (nutrient_per_100g × quantity_grams) / 100
--   - Sum across all components
-- Store in raw_* columns

-- STEP 3: Apply cooking retention factors
-- IF cooking_method_id IS NOT NULL:
--   - Query food_cooking_method_retention for each food + method
--   - IF specific retention data exists:
--       * Use food-specific retention factors
--       * data_quality_score += 0.3
--   - ELSE:
--       * Use cooking_methods.vitamin_retention_avg (generic)
--       * data_quality_score += 0.1
--       * Add warning: "Using generic retention factors for [food_name]"
--   - Calculate: adjusted_nutrient = raw_nutrient × retention_factor
-- Store in adjusted_* columns

-- STEP 4: Calculate clinical metrics
-- - Glycemic Load = (GI × available_carbs) / 100
--   * Query glycemic_load_index table for each food
--   * IF data missing → estimate based on food category
-- - PRAL (for CKD) = query renal_acid_load_data table
--   * Sum PRAL values across all foods
--   * Negative = alkaline (good for CKD)
--   * Positive = acidic (avoid in CKD)
-- - Sodium/Potassium ratio = sodium_mg / potassium_mg
--   * Target: <1.0 for hypertension

-- STEP 5: Data quality assessment
-- data_quality_score calculation:
-- - Start at 0.0
-- - For each nutrient with measured data: +0.05
-- - For each nutrient with calculated data: +0.03
-- - For each nutrient with estimated data: +0.01
-- - For each specific cooking retention factor: +0.02
-- - Divide by total_possible_points
-- - Result: 0.0-1.0

-- STEP 6: Issue warnings
-- IF vitamin_c_retention < 0.5:
--   - Warning: "Boiling reduced Vitamin C by 65%. Consider steaming to preserve nutrients."
-- IF data_quality_score < 0.5:
--   - Warning: "Nutrition data for some foods is estimated. Actual values may vary."
-- IF potassium_mg > 800 AND user has CKD:
--   - Warning: "High potassium meal (>800mg). Monitor your total daily intake."

-- STEP 7: Store calculation
-- INSERT OR IGNORE INTO meal_nutrition_calculations (...)

-- STEP 8: Compare to targets
-- - Query nutrient_targets WHERE user_id = ... AND is_active = TRUE
-- - FOR EACH target:
--     * Compare adjusted_nutrient vs target_min/target_max
--     * Calculate compliance: IN RANGE / BELOW / ABOVE
-- - Display to user:
--   "✅ Potassium: 490mg / 2000mg target (25%)"
--   "⚠️ Sodium: 1200mg / 1500mg target (80%) - Approaching limit"
--   "❌ Protein: 35g / 42-56g target - Too low"


-- ============================================================================
-- EXAMPLE: Calculation for "200g Boiled Sweet Potatoes"
-- ============================================================================

-- RAW NUTRITION (from food_nutrients table):
-- - Energy: 86 kcal/100g → 172 kcal (200g)
-- - Protein: 1.6g/100g → 3.2g
-- - Carbs: 20g/100g → 40g
-- - Fiber: 3g/100g → 6g
-- - Potassium: 337mg/100g → 674mg
-- - Vitamin C: 2.4mg/100g → 4.8mg
-- - Vitamin A: 709mcg/100g → 1418mcg

-- COOKING RETENTION (from food_cooking_method_retention, food_id=6, method_id=1):
-- - Vitamin C retention: 0.80 (80%)
-- - Potassium retention: 0.70 (70%)
-- - Vitamin A retention: 1.05 (105% - bioavailability increases!)
-- - Protein retention: 1.0 (100%)

-- ADJUSTED NUTRITION:
-- - Energy: 172 kcal (no change, calories stable)
-- - Protein: 3.2g × 1.0 = 3.2g
-- - Carbs: 40g × 0.95 = 38g (slight loss)
-- - Fiber: 6g × 0.95 = 5.7g
-- - Potassium: 674mg × 0.70 = 472mg (30% lost to water)
-- - Vitamin C: 4.8mg × 0.80 = 3.8mg (20% lost)
-- - Vitamin A: 1418mcg × 1.05 = 1489mcg (bioavailability improved!)

-- DATA QUALITY:
-- - All nutrients have measured data → 0.95 quality score
-- - Specific cooking retention factors available → +0.05
-- - Final: 1.0 (excellent)

-- WARNINGS:
-- - "Boiling reduced potassium by 30%. To retain potassium, eat cooking water or use steaming."
-- - "Vitamin A bioavailability increased by 5% with cooking. Cooked sweet potatoes are more nutritious!"

-- CLINICAL METRICS:
-- - Glycemic Load: (GI 63 × 38g carbs) / 100 = 23.9 (HIGH)
-- - PRAL: -5.6 (alkaline, good for CKD)
-- - Sodium/Potassium ratio: 36mg / 472mg = 0.08 (excellent, <1.0)

-- INSERT OR IGNORE INTO meal_nutrition_calculations (
--   meal_id, calculation_method, raw_potassium_mg, adjusted_potassium_mg,
--   cooking_method_id, total_weight_raw_g, total_weight_cooked_g,
--   glycemic_load, glycemic_load_category, pral_value, pral_category,
--   data_quality_score, calculation_warnings
-- ) VALUES (
--   123, 'component_sum', 674, 472,
--   1, 200, 220,
--   23.9, 'high', -5.6, 'alkaline',
--   1.0, '["Boiling reduced potassium by 30%", "Vitamin A bioavailability improved"]'
-- );


-- ============================================================================
-- USER INTERFACE DISPLAY
-- ============================================================================

-- Transparent nutrition display:
--
-- 🍠 Boiled Sweet Potatoes (200g)
--
-- Macros:
-- - Energy: 172 kcal
-- - Protein: 3.2g
-- - Carbs: 38g (40g raw → 95% retained)
-- - Fiber: 5.7g
--
-- Key Nutrients:
-- - ✅ Potassium: 472mg (674mg raw → 70% retained due to boiling)
-- - ⚠️ Sodium: 36mg
-- - ✅ Vitamin A: 1489mcg (+5% from cooking!)
-- - ⚠️ Vitamin C: 3.8mg (4.8mg raw → 80% retained)
--
-- Clinical Metrics:
-- - Glycemic Load: 23.9 (HIGH) ⚠️
-- - PRAL: -5.6 (Alkaline, CKD-friendly) ✅
-- - Sodium/Potassium Ratio: 0.08 (Excellent for BP) ✅
--
-- Data Quality: ⭐⭐⭐⭐⭐ (1.0/1.0) - Laboratory measured
--
-- Tips:
-- - 💡 To preserve more potassium, use steaming instead of boiling
-- - 💡 High glycemic load. Pair with protein or fat to reduce blood sugar spike
