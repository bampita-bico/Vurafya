-- Migration 068: Create PRAL and 3P Views
-- Dynamic PRAL calculation from food_nutrients
-- Individual 3P views for Protein, Potassium, Phosphorus tracking

-- ============================================================================
-- DYNAMIC PRAL VIEW (Auto-calculates from food_nutrients)
-- ============================================================================

CREATE VIEW v_pral_live AS
SELECT
    f.id AS food_id,
    f.name AS food_name,
    fn_protein.amount_per_100g AS protein_g,
    fn_phosphorus.amount_per_100g AS phosphorus_mg,
    fn_potassium.amount_per_100g AS potassium_mg,
    fn_magnesium.amount_per_100g AS magnesium_mg,
    fn_calcium.amount_per_100g AS calcium_mg,

    -- Calculate PRAL from components
    ROUND(
        (0.49 * COALESCE(fn_protein.amount_per_100g, 0)) +
        (0.037 * COALESCE(fn_phosphorus.amount_per_100g, 0)) -
        (0.021 * COALESCE(fn_potassium.amount_per_100g, 0)) -
        (0.026 * COALESCE(fn_magnesium.amount_per_100g, 0)) -
        (0.013 * COALESCE(fn_calcium.amount_per_100g, 0)),
        2
    ) AS pral_calculated,

    -- Categorize PRAL
    CASE
        WHEN (0.49 * COALESCE(fn_protein.amount_per_100g, 0) +
              0.037 * COALESCE(fn_phosphorus.amount_per_100g, 0) -
              0.021 * COALESCE(fn_potassium.amount_per_100g, 0) -
              0.026 * COALESCE(fn_magnesium.amount_per_100g, 0) -
              0.013 * COALESCE(fn_calcium.amount_per_100g, 0)) <= -3.0 THEN 'highly_alkalizing'
        WHEN (0.49 * COALESCE(fn_protein.amount_per_100g, 0) +
              0.037 * COALESCE(fn_phosphorus.amount_per_100g, 0) -
              0.021 * COALESCE(fn_potassium.amount_per_100g, 0) -
              0.026 * COALESCE(fn_magnesium.amount_per_100g, 0) -
              0.013 * COALESCE(fn_calcium.amount_per_100g, 0)) < 0 THEN 'alkalizing'
        WHEN (0.49 * COALESCE(fn_protein.amount_per_100g, 0) +
              0.037 * COALESCE(fn_phosphorus.amount_per_100g, 0) -
              0.021 * COALESCE(fn_potassium.amount_per_100g, 0) -
              0.026 * COALESCE(fn_magnesium.amount_per_100g, 0) -
              0.013 * COALESCE(fn_calcium.amount_per_100g, 0)) = 0 THEN 'neutral'
        WHEN (0.49 * COALESCE(fn_protein.amount_per_100g, 0) +
              0.037 * COALESCE(fn_phosphorus.amount_per_100g, 0) -
              0.021 * COALESCE(fn_potassium.amount_per_100g, 0) -
              0.026 * COALESCE(fn_magnesium.amount_per_100g, 0) -
              0.013 * COALESCE(fn_calcium.amount_per_100g, 0)) <= 5.0 THEN 'mildly_acidifying'
        WHEN (0.49 * COALESCE(fn_protein.amount_per_100g, 0) +
              0.037 * COALESCE(fn_phosphorus.amount_per_100g, 0) -
              0.021 * COALESCE(fn_potassium.amount_per_100g, 0) -
              0.026 * COALESCE(fn_magnesium.amount_per_100g, 0) -
              0.013 * COALESCE(fn_calcium.amount_per_100g, 0)) <= 15.0 THEN 'acidifying'
        ELSE 'highly_acidifying'
    END AS acid_category,

    -- CKD recommendation
    CASE
        WHEN (0.49 * COALESCE(fn_protein.amount_per_100g, 0) +
              0.037 * COALESCE(fn_phosphorus.amount_per_100g, 0) -
              0.021 * COALESCE(fn_potassium.amount_per_100g, 0) -
              0.026 * COALESCE(fn_magnesium.amount_per_100g, 0) -
              0.013 * COALESCE(fn_calcium.amount_per_100g, 0)) < 0 THEN 'encourage'
        WHEN (0.49 * COALESCE(fn_protein.amount_per_100g, 0) +
              0.037 * COALESCE(fn_phosphorus.amount_per_100g, 0) -
              0.021 * COALESCE(fn_potassium.amount_per_100g, 0) -
              0.026 * COALESCE(fn_magnesium.amount_per_100g, 0) -
              0.013 * COALESCE(fn_calcium.amount_per_100g, 0)) <= 5.0 THEN 'moderate'
        ELSE 'limit'
    END AS ckd_recommendation

FROM foods f
LEFT JOIN food_nutrients fn_protein ON f.id = fn_protein.food_id AND fn_protein.nutrient_id = 1
LEFT JOIN food_nutrients fn_phosphorus ON f.id = fn_phosphorus.food_id AND fn_phosphorus.nutrient_id = 26
LEFT JOIN food_nutrients fn_potassium ON f.id = fn_potassium.food_id AND fn_potassium.nutrient_id = 29
LEFT JOIN food_nutrients fn_magnesium ON f.id = fn_magnesium.food_id AND fn_magnesium.nutrient_id = 31
LEFT JOIN food_nutrients fn_calcium ON f.id = fn_calcium.food_id AND fn_calcium.nutrient_id = 25
WHERE fn_protein.amount_per_100g IS NOT NULL
  AND fn_phosphorus.amount_per_100g IS NOT NULL
  AND fn_potassium.amount_per_100g IS NOT NULL;

-- ============================================================================
-- INDIVIDUAL 3P VIEWS (Protein, Potassium, Phosphorus)
-- ============================================================================

-- View: v_protein_content
-- For CKD protein restriction (0.6-0.8g/kg body weight)
CREATE VIEW v_protein_content AS
SELECT
    f.id AS food_id,
    f.name AS food_name,
    f.category_id,
    fn.amount_per_100g AS protein_g_per_100g,
    CASE
        WHEN fn.amount_per_100g < 2 THEN 'very_low'
        WHEN fn.amount_per_100g < 5 THEN 'low'
        WHEN fn.amount_per_100g < 10 THEN 'moderate'
        WHEN fn.amount_per_100g < 20 THEN 'high'
        ELSE 'very_high'
    END AS protein_category,
    CASE
        WHEN fn.amount_per_100g < 10 THEN 'safe'
        WHEN fn.amount_per_100g < 20 THEN 'moderate'
        ELSE 'limit'
    END AS ckd_recommendation
FROM foods f
JOIN food_nutrients fn ON f.id = fn.food_id
WHERE fn.nutrient_id = 1  -- Protein
ORDER BY fn.amount_per_100g DESC;

-- View: v_potassium_content
-- For CKD potassium management (fluctuates rapidly with dialysis)
CREATE VIEW v_potassium_content AS
SELECT
    f.id AS food_id,
    f.name AS food_name,
    f.category_id,
    fn.amount_per_100g AS potassium_mg_per_100g,
    CASE
        WHEN fn.amount_per_100g < 100 THEN 'very_low'
        WHEN fn.amount_per_100g < 200 THEN 'low'
        WHEN fn.amount_per_100g < 300 THEN 'moderate'
        WHEN fn.amount_per_100g < 500 THEN 'high'
        ELSE 'very_high'
    END AS potassium_category,
    CASE
        WHEN fn.amount_per_100g < 200 THEN 'safe_for_hyperkalemia'
        WHEN fn.amount_per_100g < 400 THEN 'moderate'
        ELSE 'avoid_if_hyperkalemic'
    END AS ckd_recommendation
FROM foods f
JOIN food_nutrients fn ON f.id = fn.food_id
WHERE fn.nutrient_id = 29  -- Potassium
ORDER BY fn.amount_per_100g DESC;

-- View: v_phosphorus_content
-- For CKD phosphorus restriction (800-1000mg/day for Stage 3-4)
CREATE VIEW v_phosphorus_content AS
SELECT
    f.id AS food_id,
    f.name AS food_name,
    f.category_id,
    fn.amount_per_100g AS phosphorus_mg_per_100g,
    CASE
        WHEN fn.amount_per_100g < 50 THEN 'very_low'
        WHEN fn.amount_per_100g < 100 THEN 'low'
        WHEN fn.amount_per_100g < 200 THEN 'moderate'
        WHEN fn.amount_per_100g < 400 THEN 'high'
        ELSE 'very_high'
    END AS phosphorus_category,
    CASE
        WHEN fn.amount_per_100g < 100 THEN 'safe'
        WHEN fn.amount_per_100g < 200 THEN 'moderate'
        ELSE 'limit'
    END AS ckd_recommendation
FROM foods f
JOIN food_nutrients fn ON f.id = fn.food_id
WHERE fn.nutrient_id = 26  -- Phosphorus
ORDER BY fn.amount_per_100g DESC;

-- View: v_3p_combined
-- Show all 3Ps together for comprehensive CKD monitoring
CREATE VIEW v_3p_combined AS
SELECT
    f.id AS food_id,
    f.name AS food_name,
    f.category_id,
    protein.amount_per_100g AS protein_g,
    potassium.amount_per_100g AS potassium_mg,
    phosphorus.amount_per_100g AS phosphorus_mg,

    -- Individual categories
    CASE WHEN protein.amount_per_100g < 10 THEN 'low' ELSE 'high' END AS protein_level,
    CASE WHEN potassium.amount_per_100g < 200 THEN 'low' ELSE 'high' END AS potassium_level,
    CASE WHEN phosphorus.amount_per_100g < 100 THEN 'low' ELSE 'high' END AS phosphorus_level,

    -- Overall CKD safety
    CASE
        WHEN protein.amount_per_100g < 10
         AND potassium.amount_per_100g < 200
         AND phosphorus.amount_per_100g < 100 THEN 'very_safe'
        WHEN protein.amount_per_100g < 15
         AND potassium.amount_per_100g < 300
         AND phosphorus.amount_per_100g < 150 THEN 'safe'
        WHEN protein.amount_per_100g < 20
         AND potassium.amount_per_100g < 400
         AND phosphorus.amount_per_100g < 200 THEN 'moderate'
        ELSE 'limit'
    END AS ckd_overall_recommendation

FROM foods f
LEFT JOIN food_nutrients protein ON f.id = protein.food_id AND protein.nutrient_id = 1
LEFT JOIN food_nutrients potassium ON f.id = potassium.food_id AND potassium.nutrient_id = 29
LEFT JOIN food_nutrients phosphorus ON f.id = phosphorus.food_id AND phosphorus.nutrient_id = 26
WHERE protein.amount_per_100g IS NOT NULL
  AND potassium.amount_per_100g IS NOT NULL
  AND phosphorus.amount_per_100g IS NOT NULL;
