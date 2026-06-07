-- Migration 070: Daily 3P Summary Dashboard
-- Track daily intake vs. targets for Protein, Potassium, Phosphorus separately
-- Critical for CKD patients to monitor compliance

-- ============================================================================
-- DAILY 3P TRACKING VIEW
-- ============================================================================

CREATE VIEW v_daily_3p_tracking AS
SELECT
    u.id AS user_id,
    u.username,
    DATE(m.meal_time) AS date,

    -- Daily totals (sum of all meals for the day)
    SUM(mnc.protein_g_total) AS daily_protein_g,
    SUM(mnc.potassium_mg_total) AS daily_potassium_mg,
    SUM(mnc.phosphorus_mg_total) AS daily_phosphorus_mg,

    -- Daily PRAL total (acid-base balance)
    SUM(mnc.pral_value) AS daily_pral,

    -- Targets from nutrient_targets table (personalized per user)
    nt_protein.target_value AS protein_target_g,
    nt_potassium.target_value AS potassium_target_mg,
    nt_phosphorus.target_value AS phosphorus_target_mg,

    -- % of target achieved
    ROUND(SUM(mnc.protein_g_total) * 100.0 / NULLIF(nt_protein.target_value, 0), 1) AS protein_pct_of_target,
    ROUND(SUM(mnc.potassium_mg_total) * 100.0 / NULLIF(nt_potassium.target_value, 0), 1) AS potassium_pct_of_target,
    ROUND(SUM(mnc.phosphorus_mg_total) * 100.0 / NULLIF(nt_phosphorus.target_value, 0), 1) AS phosphorus_pct_of_target,

    -- Status: OK (within target) or OVER (exceeded target)
    CASE
        WHEN SUM(mnc.protein_g_total) > nt_protein.target_value THEN 'OVER'
        WHEN SUM(mnc.protein_g_total) IS NULL THEN 'NO_DATA'
        ELSE 'OK'
    END AS protein_status,

    CASE
        WHEN SUM(mnc.potassium_mg_total) > nt_potassium.target_value THEN 'OVER'
        WHEN SUM(mnc.potassium_mg_total) IS NULL THEN 'NO_DATA'
        ELSE 'OK'
    END AS potassium_status,

    CASE
        WHEN SUM(mnc.phosphorus_mg_total) > nt_phosphorus.target_value THEN 'OVER'
        WHEN SUM(mnc.phosphorus_mg_total) IS NULL THEN 'NO_DATA'
        ELSE 'OK'
    END AS phosphorus_status,

    -- Overall CKD compliance (all 3Ps within targets = COMPLIANT)
    CASE
        WHEN SUM(mnc.protein_g_total) <= nt_protein.target_value
         AND SUM(mnc.potassium_mg_total) <= nt_potassium.target_value
         AND SUM(mnc.phosphorus_mg_total) <= nt_phosphorus.target_value
        THEN 'COMPLIANT'
        WHEN (SUM(mnc.protein_g_total) > nt_protein.target_value * 1.2)
          OR (SUM(mnc.potassium_mg_total) > nt_potassium.target_value * 1.2)
          OR (SUM(mnc.phosphorus_mg_total) > nt_phosphorus.target_value * 1.2)
        THEN 'CRITICAL'
        ELSE 'NON_COMPLIANT'
    END AS overall_compliance,

    -- Count meals logged today
    COUNT(DISTINCT m.id) AS meals_logged_today

FROM users u
JOIN meals m ON u.id = m.user_id
JOIN meal_nutrition_calculations mnc ON m.id = mnc.meal_id
LEFT JOIN nutrient_targets nt_protein
    ON u.id = nt_protein.user_id
    AND nt_protein.nutrient_id = 1
LEFT JOIN nutrient_targets nt_potassium
    ON u.id = nt_potassium.user_id
    AND nt_potassium.nutrient_id = 29
LEFT JOIN nutrient_targets nt_phosphorus
    ON u.id = nt_phosphorus.user_id
    AND nt_phosphorus.nutrient_id = 26
WHERE mnc.protein_g_total IS NOT NULL
  AND mnc.potassium_mg_total IS NOT NULL
  AND mnc.phosphorus_mg_total IS NOT NULL
GROUP BY u.id, DATE(m.meal_time);

-- ============================================================================
-- VERIFICATION QUERY
-- ============================================================================

-- Check view works (will return 0 rows if no meal data yet)
SELECT
    'View v_daily_3p_tracking created' AS status,
    COUNT(*) AS sample_row_count
FROM v_daily_3p_tracking
LIMIT 1;
