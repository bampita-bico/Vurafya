-- Migration 069: Meal-Level 3P Tracking
-- Track Protein, Potassium, Phosphorus individually at meal level
-- Critical for CKD patients on dialysis (rapid fluctuations)

-- ============================================================================
-- EXTEND MEAL_NUTRITION_CALCULATIONS TABLE
-- ============================================================================

-- Add individual 3P totals (actual values)
ALTER TABLE meal_nutrition_calculations ADD COLUMN protein_g_total REAL;
ALTER TABLE meal_nutrition_calculations ADD COLUMN potassium_mg_total REAL;
ALTER TABLE meal_nutrition_calculations ADD COLUMN phosphorus_mg_total REAL;

-- Add individual 3P status flags (safe/moderate/high)
ALTER TABLE meal_nutrition_calculations ADD COLUMN protein_status VARCHAR(20);
ALTER TABLE meal_nutrition_calculations ADD COLUMN potassium_status VARCHAR(20);
ALTER TABLE meal_nutrition_calculations ADD COLUMN phosphorus_status VARCHAR(20);

-- Add overall 3P recommendation for CKD safety
ALTER TABLE meal_nutrition_calculations ADD COLUMN ckd_3p_recommendation VARCHAR(50);

-- Add PRAL value for meal (acid-base balance)
ALTER TABLE meal_nutrition_calculations ADD COLUMN pral_value REAL;
ALTER TABLE meal_nutrition_calculations ADD COLUMN pral_category VARCHAR(30);

-- Add magnesium and calcium (for PRAL calculation transparency)
ALTER TABLE meal_nutrition_calculations ADD COLUMN magnesium_mg_total REAL;
ALTER TABLE meal_nutrition_calculations ADD COLUMN calcium_mg_total REAL;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_meal_calc_protein ON meal_nutrition_calculations(protein_g_total);
CREATE INDEX IF NOT EXISTS idx_meal_calc_potassium ON meal_nutrition_calculations(potassium_mg_total);
CREATE INDEX IF NOT EXISTS idx_meal_calc_phosphorus ON meal_nutrition_calculations(phosphorus_mg_total);
CREATE INDEX IF NOT EXISTS idx_meal_calc_ckd_recommendation ON meal_nutrition_calculations(ckd_3p_recommendation);

-- ============================================================================
-- POPULATE EXISTING MEAL CALCULATIONS (if any exist)
-- ============================================================================

-- Calculate protein totals for existing meals
UPDATE meal_nutrition_calculations
SET protein_g_total = (
    SELECT SUM(fn.amount_per_100g * mc.quantity_grams / 100.0)
    FROM meal_components mc
    JOIN food_nutrients fn ON mc.food_id = fn.food_id
    WHERE mc.meal_id = meal_nutrition_calculations.meal_id
      AND fn.nutrient_id = 1  -- Protein
)
WHERE meal_id IN (SELECT DISTINCT meal_id FROM meal_components);

-- Calculate potassium totals for existing meals
UPDATE meal_nutrition_calculations
SET potassium_mg_total = (
    SELECT SUM(fn.amount_per_100g * mc.quantity_grams / 100.0)
    FROM meal_components mc
    JOIN food_nutrients fn ON mc.food_id = fn.food_id
    WHERE mc.meal_id = meal_nutrition_calculations.meal_id
      AND fn.nutrient_id = 29  -- Potassium
)
WHERE meal_id IN (SELECT DISTINCT meal_id FROM meal_components);

-- Calculate phosphorus totals for existing meals
UPDATE meal_nutrition_calculations
SET phosphorus_mg_total = (
    SELECT SUM(fn.amount_per_100g * mc.quantity_grams / 100.0)
    FROM meal_components mc
    JOIN food_nutrients fn ON mc.food_id = fn.food_id
    WHERE mc.meal_id = meal_nutrition_calculations.meal_id
      AND fn.nutrient_id = 26  -- Phosphorus
)
WHERE meal_id IN (SELECT DISTINCT meal_id FROM meal_components);

-- Calculate magnesium totals (for PRAL)
UPDATE meal_nutrition_calculations
SET magnesium_mg_total = (
    SELECT SUM(fn.amount_per_100g * mc.quantity_grams / 100.0)
    FROM meal_components mc
    JOIN food_nutrients fn ON mc.food_id = fn.food_id
    WHERE mc.meal_id = meal_nutrition_calculations.meal_id
      AND fn.nutrient_id = 31  -- Magnesium
)
WHERE meal_id IN (SELECT DISTINCT meal_id FROM meal_components);

-- Calculate calcium totals (for PRAL)
UPDATE meal_nutrition_calculations
SET calcium_mg_total = (
    SELECT SUM(fn.amount_per_100g * mc.quantity_grams / 100.0)
    FROM meal_components mc
    JOIN food_nutrients fn ON mc.food_id = fn.food_id
    WHERE mc.meal_id = meal_nutrition_calculations.meal_id
      AND fn.nutrient_id = 25  -- Calcium
)
WHERE meal_id IN (SELECT DISTINCT meal_id FROM meal_components);

-- ============================================================================
-- CALCULATE PRAL FOR MEALS
-- ============================================================================
-- PRAL formula: 0.49×protein + 0.037×P - 0.021×K - 0.026×Mg - 0.013×Ca

UPDATE meal_nutrition_calculations
SET pral_value = ROUND(
    (0.49 * COALESCE(protein_g_total, 0)) +
    (0.037 * COALESCE(phosphorus_mg_total, 0)) -
    (0.021 * COALESCE(potassium_mg_total, 0)) -
    (0.026 * COALESCE(magnesium_mg_total, 0)) -
    (0.013 * COALESCE(calcium_mg_total, 0)),
    2
)
WHERE protein_g_total IS NOT NULL
  AND phosphorus_mg_total IS NOT NULL
  AND potassium_mg_total IS NOT NULL;

-- Categorize PRAL
UPDATE meal_nutrition_calculations
SET pral_category = CASE
    WHEN pral_value <= -3.0 THEN 'highly_alkalizing'
    WHEN pral_value < 0 THEN 'alkalizing'
    WHEN pral_value = 0 THEN 'neutral'
    WHEN pral_value <= 5.0 THEN 'mildly_acidifying'
    WHEN pral_value <= 15.0 THEN 'acidifying'
    ELSE 'highly_acidifying'
END
WHERE pral_value IS NOT NULL;

-- ============================================================================
-- CALCULATE 3P STATUS FLAGS
-- ============================================================================

-- Protein status (CKD target: <10g per meal for 0.6g/kg/day diet)
UPDATE meal_nutrition_calculations
SET protein_status = CASE
    WHEN protein_g_total < 5 THEN 'very_low'
    WHEN protein_g_total < 10 THEN 'safe'
    WHEN protein_g_total < 15 THEN 'moderate'
    WHEN protein_g_total < 25 THEN 'high'
    ELSE 'very_high'
END
WHERE protein_g_total IS NOT NULL;

-- Potassium status (CKD: varies with dialysis, general guideline)
UPDATE meal_nutrition_calculations
SET potassium_status = CASE
    WHEN potassium_mg_total < 200 THEN 'very_low'
    WHEN potassium_mg_total < 400 THEN 'safe'
    WHEN potassium_mg_total < 600 THEN 'moderate'
    WHEN potassium_mg_total < 1000 THEN 'high'
    ELSE 'very_high'
END
WHERE potassium_mg_total IS NOT NULL;

-- Phosphorus status (CKD target: <300mg per meal for 800-1000mg/day diet)
UPDATE meal_nutrition_calculations
SET phosphorus_status = CASE
    WHEN phosphorus_mg_total < 100 THEN 'very_low'
    WHEN phosphorus_mg_total < 250 THEN 'safe'
    WHEN phosphorus_mg_total < 400 THEN 'moderate'
    WHEN phosphorus_mg_total < 600 THEN 'high'
    ELSE 'very_high'
END
WHERE phosphorus_mg_total IS NOT NULL;

-- ============================================================================
-- CALCULATE OVERALL CKD RECOMMENDATION
-- ============================================================================

UPDATE meal_nutrition_calculations
SET ckd_3p_recommendation = CASE
    -- Very safe: All 3Ps in safe ranges
    WHEN protein_g_total < 10
     AND potassium_mg_total < 400
     AND phosphorus_mg_total < 250 THEN 'very_safe'

    -- Safe: All 3Ps moderate or below
    WHEN protein_g_total < 15
     AND potassium_mg_total < 600
     AND phosphorus_mg_total < 400 THEN 'safe'

    -- Moderate: One P is high, others are acceptable
    WHEN (protein_g_total < 25 OR potassium_mg_total < 1000 OR phosphorus_mg_total < 600)
     AND NOT (protein_g_total >= 25 AND potassium_mg_total >= 1000)
     AND NOT (protein_g_total >= 25 AND phosphorus_mg_total >= 600)
     AND NOT (potassium_mg_total >= 1000 AND phosphorus_mg_total >= 600) THEN 'moderate'

    -- Limit: Two or more Ps are high
    WHEN (protein_g_total >= 25 AND potassium_mg_total >= 1000)
      OR (protein_g_total >= 25 AND phosphorus_mg_total >= 600)
      OR (potassium_mg_total >= 1000 AND phosphorus_mg_total >= 600) THEN 'limit'

    -- Critical: All 3Ps are very high
    ELSE 'critical'
END
WHERE protein_g_total IS NOT NULL
  AND potassium_mg_total IS NOT NULL
  AND phosphorus_mg_total IS NOT NULL;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check meal-level 3P tracking coverage
SELECT
    'Total meals with calculations' AS metric,
    COUNT(*) AS value
FROM meal_nutrition_calculations
UNION ALL
SELECT
    'Meals with 3P data',
    COUNT(*)
FROM meal_nutrition_calculations
WHERE protein_g_total IS NOT NULL
  AND potassium_mg_total IS NOT NULL
  AND phosphorus_mg_total IS NOT NULL
UNION ALL
SELECT
    'Meals marked as safe for CKD',
    COUNT(*)
FROM meal_nutrition_calculations
WHERE ckd_3p_recommendation IN ('very_safe', 'safe')
UNION ALL
SELECT
    'Meals to limit for CKD',
    COUNT(*)
FROM meal_nutrition_calculations
WHERE ckd_3p_recommendation IN ('limit', 'critical');
