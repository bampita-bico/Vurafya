-- Migration 067: Add Missing PRAL Components for Full Precision
-- Adds magnesium and calcium to enable complete PRAL recalculation
-- Also adds verification columns to ensure data quality

-- ============================================================================
-- EXTEND RENAL_ACID_LOAD_DATA TABLE
-- ============================================================================

-- Add missing PRAL components (Mg and Ca)
ALTER TABLE renal_acid_load_data ADD COLUMN magnesium_mg REAL;
ALTER TABLE renal_acid_load_data ADD COLUMN calcium_mg REAL;

-- Add data quality flags
ALTER TABLE renal_acid_load_data ADD COLUMN components_complete BOOLEAN DEFAULT FALSE;

-- Add calculation verification columns
ALTER TABLE renal_acid_load_data ADD COLUMN pral_calculated REAL;  -- Auto-calculated from components
ALTER TABLE renal_acid_load_data ADD COLUMN pral_difference REAL;  -- pral_calculated - pral_value (for quality check)

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_pral_food ON renal_acid_load_data(food_id);
CREATE INDEX IF NOT EXISTS idx_pral_complete ON renal_acid_load_data(components_complete);

-- ============================================================================
-- POPULATE MISSING COMPONENTS FROM FOOD_NUTRIENTS
-- ============================================================================

-- Update magnesium values from food_nutrients table
UPDATE renal_acid_load_data
SET magnesium_mg = (
    SELECT fn.amount_per_100g
    FROM food_nutrients fn
    WHERE fn.food_id = renal_acid_load_data.food_id
      AND fn.nutrient_id = 31  -- Magnesium
    LIMIT 1
)
WHERE food_id IN (SELECT DISTINCT food_id FROM food_nutrients WHERE nutrient_id = 31);

-- Update calcium values from food_nutrients table
UPDATE renal_acid_load_data
SET calcium_mg = (
    SELECT fn.amount_per_100g
    FROM food_nutrients fn
    WHERE fn.food_id = renal_acid_load_data.food_id
      AND fn.nutrient_id = 25  -- Calcium
    LIMIT 1
)
WHERE food_id IN (SELECT DISTINCT food_id FROM food_nutrients WHERE nutrient_id = 25);

-- Mark records as complete if all 5 PRAL components present
UPDATE renal_acid_load_data
SET components_complete = TRUE
WHERE protein_g IS NOT NULL
  AND phosphorus_mg IS NOT NULL
  AND potassium_mg IS NOT NULL
  AND magnesium_mg IS NOT NULL
  AND calcium_mg IS NOT NULL;

-- ============================================================================
-- CALCULATE PRAL FROM COMPONENTS FOR VERIFICATION
-- ============================================================================
-- PRAL formula: 0.49×protein + 0.037×P - 0.021×K - 0.026×Mg - 0.013×Ca

UPDATE renal_acid_load_data
SET pral_calculated = ROUND(
    (0.49 * COALESCE(protein_g, 0)) +
    (0.037 * COALESCE(phosphorus_mg, 0)) -
    (0.021 * COALESCE(potassium_mg, 0)) -
    (0.026 * COALESCE(magnesium_mg, 0)) -
    (0.013 * COALESCE(calcium_mg, 0)),
    2
)
WHERE components_complete = TRUE;

-- Calculate difference between calculated and stored PRAL (quality check)
UPDATE renal_acid_load_data
SET pral_difference = ROUND(pral_calculated - pral_value, 2)
WHERE pral_calculated IS NOT NULL AND pral_value IS NOT NULL;

-- ============================================================================
-- VERIFICATION QUERY
-- ============================================================================
-- Check how many foods have complete components and how accurate PRAL calculations are

SELECT
    'Total foods with PRAL data' AS metric,
    COUNT(*) AS value
FROM renal_acid_load_data
UNION ALL
SELECT
    'Foods with complete components',
    COUNT(*)
FROM renal_acid_load_data
WHERE components_complete = TRUE
UNION ALL
SELECT
    'Average PRAL difference',
    ROUND(AVG(ABS(pral_difference)), 3)
FROM renal_acid_load_data
WHERE pral_difference IS NOT NULL
UNION ALL
SELECT
    'Max PRAL difference',
    ROUND(MAX(ABS(pral_difference)), 2)
FROM renal_acid_load_data
WHERE pral_difference IS NOT NULL;
