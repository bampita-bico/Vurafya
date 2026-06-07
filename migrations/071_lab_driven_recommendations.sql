-- Migration 071: Lab-Driven Dynamic Recommendations
-- Potassium recommendations change based on current lab values
-- Critical for dialysis patients (hyperkalemia → hypokalemia in days)

-- ============================================================================
-- USER CURRENT POTASSIUM STATUS VIEW
-- ============================================================================

CREATE VIEW v_user_current_potassium_status AS
SELECT
    user_id,
    potassium_value AS current_k,
    measured_at AS last_measured,

    -- K+ status categories
    CASE
        WHEN potassium_value < 3.5 THEN 'low'
        WHEN potassium_value <= 5.0 THEN 'normal'
        WHEN potassium_value <= 5.5 THEN 'borderline_high'
        WHEN potassium_value <= 6.0 THEN 'high'
        ELSE 'critical'
    END AS k_status,

    -- Dietary recommendation (changes with K+ level)
    CASE
        WHEN potassium_value < 3.5 THEN 'recommend_high_k_foods'
        WHEN potassium_value <= 5.0 THEN 'normal_diet'
        WHEN potassium_value <= 5.5 THEN 'moderate_k_restriction'
        ELSE 'strict_k_restriction'
    END AS dietary_recommendation,

    -- Days since last measurement
    CAST((julianday('now') - julianday(measured_at)) AS INTEGER) AS days_since_measurement

FROM potassium_logs
WHERE (user_id, measured_at) IN (
    SELECT user_id, MAX(measured_at)
    FROM potassium_logs
    GROUP BY user_id
);

-- ============================================================================
-- USER CURRENT PHOSPHORUS STATUS VIEW
-- ============================================================================

CREATE VIEW v_user_current_phosphorus_status AS
SELECT
    user_id,
    phosphorus_mg_dl AS current_p,
    measured_at AS last_measured,

    -- P status categories
    CASE
        WHEN phosphorus_mg_dl < 2.5 THEN 'low'
        WHEN phosphorus_mg_dl <= 4.5 THEN 'normal'
        WHEN phosphorus_mg_dl <= 5.5 THEN 'borderline_high'
        WHEN phosphorus_mg_dl <= 7.0 THEN 'high'
        ELSE 'critical'
    END AS p_status,

    -- Dietary recommendation
    CASE
        WHEN phosphorus_mg_dl < 2.5 THEN 'increase_phosphorus'
        WHEN phosphorus_mg_dl <= 4.5 THEN 'maintain_current'
        WHEN phosphorus_mg_dl <= 5.5 THEN 'moderate_p_restriction'
        ELSE 'strict_p_restriction'
    END AS dietary_recommendation,

    -- Days since last measurement
    CAST((julianday('now') - julianday(measured_at)) AS INTEGER) AS days_since_measurement

FROM phosphorus_logs
WHERE (user_id, measured_at) IN (
    SELECT user_id, MAX(measured_at)
    FROM phosphorus_logs
    GROUP BY user_id
);

-- ============================================================================
-- USER CURRENT EGFR STATUS VIEW (CKD Staging)
-- ============================================================================

CREATE VIEW v_user_current_egfr_status AS
SELECT
    user_id,
    egfr_ml_min AS current_egfr,
    creatinine_mg_dl,
    measured_at AS last_measured,

    -- CKD stage based on eGFR
    CASE
        WHEN egfr_ml_min >= 90 THEN 'stage_1_normal'
        WHEN egfr_ml_min >= 60 THEN 'stage_2_mild'
        WHEN egfr_ml_min >= 45 THEN 'stage_3a_moderate'
        WHEN egfr_ml_min >= 30 THEN 'stage_3b_moderate'
        WHEN egfr_ml_min >= 15 THEN 'stage_4_severe'
        ELSE 'stage_5_kidney_failure'
    END AS ckd_stage,

    -- Protein restriction level
    CASE
        WHEN egfr_ml_min >= 60 THEN 'no_restriction'
        WHEN egfr_ml_min >= 30 THEN 'moderate_restriction_0.8g_per_kg'
        ELSE 'strict_restriction_0.6g_per_kg'
    END AS protein_recommendation,

    -- Days since last measurement
    CAST((julianday('now') - julianday(measured_at)) AS INTEGER) AS days_since_measurement

FROM creatinine_egfr_logs
WHERE (user_id, measured_at) IN (
    SELECT user_id, MAX(measured_at)
    FROM creatinine_egfr_logs
    GROUP BY user_id
);

-- ============================================================================
-- COMBINED CKD LAB STATUS VIEW
-- ============================================================================

CREATE VIEW v_user_ckd_lab_status AS
SELECT
    u.id AS user_id,
    u.username,

    -- Potassium status
    k.current_k,
    k.k_status,
    k.dietary_recommendation AS k_recommendation,
    k.days_since_measurement AS k_days_old,

    -- Phosphorus status
    p.current_p,
    p.p_status,
    p.dietary_recommendation AS p_recommendation,
    p.days_since_measurement AS p_days_old,

    -- eGFR status
    e.current_egfr,
    e.ckd_stage,
    e.protein_recommendation,
    e.days_since_measurement AS egfr_days_old,

    -- Overall lab freshness warning
    CASE
        WHEN COALESCE(k.days_since_measurement, 999) > 30
          OR COALESCE(p.days_since_measurement, 999) > 30
          OR COALESCE(e.days_since_measurement, 999) > 90
        THEN 'LABS_OUTDATED'
        WHEN COALESCE(k.days_since_measurement, 999) > 14
          OR COALESCE(p.days_since_measurement, 999) > 14
          OR COALESCE(e.days_since_measurement, 999) > 30
        THEN 'LABS_AGING'
        ELSE 'LABS_CURRENT'
    END AS lab_freshness

FROM users u
LEFT JOIN v_user_current_potassium_status k ON u.id = k.user_id
LEFT JOIN v_user_current_phosphorus_status p ON u.id = p.user_id
LEFT JOIN v_user_current_egfr_status e ON u.id = e.user_id
WHERE k.user_id IS NOT NULL
   OR p.user_id IS NOT NULL
   OR e.user_id IS NOT NULL;

-- ============================================================================
-- DYNAMIC FOOD RECOMMENDATIONS VIEW
-- ============================================================================

CREATE VIEW v_dynamic_food_recommendations AS
SELECT
    u.id AS user_id,
    u.username,
    f.id AS food_id,
    f.name AS food_name,

    -- Get food's 3P values
    vp.protein_g_per_100g,
    vk.potassium_mg_per_100g,
    vph.phosphorus_mg_per_100g,

    -- User's current lab status
    labs.k_status,
    labs.k_recommendation,
    labs.p_status,
    labs.p_recommendation,
    labs.ckd_stage,
    labs.protein_recommendation,

    -- Dynamic recommendation based on CURRENT labs
    CASE
        -- CRITICAL: Avoid if hyperkalemic and food is high K+
        WHEN labs.k_recommendation = 'strict_k_restriction'
         AND vk.potassium_mg_per_100g > 400 THEN 'AVOID_HIGH_POTASSIUM'

        -- ENCOURAGE: Recommend high K+ if hypokalemic
        WHEN labs.k_recommendation = 'recommend_high_k_foods'
         AND vk.potassium_mg_per_100g > 500 THEN 'ENCOURAGE_HIGH_POTASSIUM'

        -- Avoid high phosphorus if P is elevated
        WHEN labs.p_recommendation IN ('moderate_p_restriction', 'strict_p_restriction')
         AND vph.phosphorus_mg_per_100g > 200 THEN 'LIMIT_HIGH_PHOSPHORUS'

        -- Avoid high protein if CKD Stage 3B+
        WHEN labs.protein_recommendation = 'strict_restriction_0.6g_per_kg'
         AND vp.protein_g_per_100g > 15 THEN 'LIMIT_HIGH_PROTEIN'

        -- Safe for current status
        ELSE 'SAFE'
    END AS dynamic_recommendation

FROM users u
CROSS JOIN foods f
LEFT JOIN v_protein_content vp ON f.id = vp.food_id
LEFT JOIN v_potassium_content vk ON f.id = vk.food_id
LEFT JOIN v_phosphorus_content vph ON f.id = vph.food_id
LEFT JOIN v_user_ckd_lab_status labs ON u.id = labs.user_id
WHERE vp.food_id IS NOT NULL
  AND vk.food_id IS NOT NULL
  AND vph.food_id IS NOT NULL
  AND labs.user_id IS NOT NULL;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check potassium status view
SELECT
    'View v_user_current_potassium_status created' AS status,
    COUNT(*) AS users_with_k_data
FROM v_user_current_potassium_status;

-- Check phosphorus status view
SELECT
    'View v_user_current_phosphorus_status created' AS status,
    COUNT(*) AS users_with_p_data
FROM v_user_current_phosphorus_status;

-- Check eGFR status view
SELECT
    'View v_user_current_egfr_status created' AS status,
    COUNT(*) AS users_with_egfr_data
FROM v_user_current_egfr_status;

-- Check combined CKD lab status view
SELECT
    'View v_user_ckd_lab_status created' AS status,
    COUNT(*) AS users_with_any_lab_data
FROM v_user_ckd_lab_status;
