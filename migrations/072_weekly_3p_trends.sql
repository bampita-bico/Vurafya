-- Migration 072: Weekly 3P Trend Tracking
-- Critical for dialysis patients (rapid fluctuations)
-- Correlate dietary intake with lab results

-- ============================================================================
-- WEEKLY 3P TRENDS VIEW
-- ============================================================================

CREATE VIEW v_weekly_3p_trends AS
SELECT
    user_id,
    strftime('%Y-W%W', meal_time) AS week,
    strftime('%Y', meal_time) AS year,
    strftime('%W', meal_time) AS week_number,

    -- Weekly averages (mean daily intake per week)
    AVG(daily_protein_g) AS avg_daily_protein_g,
    AVG(daily_potassium_mg) AS avg_daily_potassium_mg,
    AVG(daily_phosphorus_mg) AS avg_daily_phosphorus_mg,
    AVG(daily_pral) AS avg_daily_pral,

    -- Week-over-week changes (compare to previous week)
    LAG(AVG(daily_protein_g)) OVER (PARTITION BY user_id ORDER BY strftime('%Y-W%W', meal_time)) AS prev_week_protein,
    LAG(AVG(daily_potassium_mg)) OVER (PARTITION BY user_id ORDER BY strftime('%Y-W%W', meal_time)) AS prev_week_potassium,
    LAG(AVG(daily_phosphorus_mg)) OVER (PARTITION BY user_id ORDER BY strftime('%Y-W%W', meal_time)) AS prev_week_phosphorus,

    -- Change amounts
    AVG(daily_protein_g) - LAG(AVG(daily_protein_g)) OVER (PARTITION BY user_id ORDER BY strftime('%Y-W%W', meal_time)) AS protein_change,
    AVG(daily_potassium_mg) - LAG(AVG(daily_potassium_mg)) OVER (PARTITION BY user_id ORDER BY strftime('%Y-W%W', meal_time)) AS potassium_change,
    AVG(daily_phosphorus_mg) - LAG(AVG(daily_phosphorus_mg)) OVER (PARTITION BY user_id ORDER BY strftime('%Y-W%W', meal_time)) AS phosphorus_change,

    -- Alert flags for rapid changes (>500mg K+ change = ALERT)
    CASE
        WHEN ABS(AVG(daily_potassium_mg) - LAG(AVG(daily_potassium_mg)) OVER (PARTITION BY user_id ORDER BY strftime('%Y-W%W', meal_time))) > 500
        THEN 'ALERT'
        WHEN ABS(AVG(daily_potassium_mg) - LAG(AVG(daily_potassium_mg)) OVER (PARTITION BY user_id ORDER BY strftime('%Y-W%W', meal_time))) > 300
        THEN 'WARNING'
        ELSE 'OK'
    END AS potassium_change_alert,

    CASE
        WHEN ABS(AVG(daily_phosphorus_mg) - LAG(AVG(daily_phosphorus_mg)) OVER (PARTITION BY user_id ORDER BY strftime('%Y-W%W', meal_time))) > 200
        THEN 'ALERT'
        WHEN ABS(AVG(daily_phosphorus_mg) - LAG(AVG(daily_phosphorus_mg)) OVER (PARTITION BY user_id ORDER BY strftime('%Y-W%W', meal_time))) > 100
        THEN 'WARNING'
        ELSE 'OK'
    END AS phosphorus_change_alert,

    -- Days logged in this week
    COUNT(DISTINCT DATE(meal_time)) AS days_logged,

    -- Compliance rate (7 days expected per week)
    ROUND(COUNT(DISTINCT DATE(meal_time)) * 100.0 / 7.0, 1) AS logging_compliance_pct

FROM (
    SELECT
        u.id AS user_id,
        m.meal_time,
        DATE(m.meal_time) AS date,
        SUM(mnc.protein_g_total) AS daily_protein_g,
        SUM(mnc.potassium_mg_total) AS daily_potassium_mg,
        SUM(mnc.phosphorus_mg_total) AS daily_phosphorus_mg,
        SUM(mnc.pral_value) AS daily_pral
    FROM users u
    JOIN meals m ON u.id = m.user_id
    JOIN meal_nutrition_calculations mnc ON m.id = mnc.meal_id
    WHERE mnc.protein_g_total IS NOT NULL
    GROUP BY u.id, DATE(m.meal_time)
)
GROUP BY user_id, strftime('%Y-W%W', meal_time);

-- ============================================================================
-- 3P INTAKE VS LABS VIEW (Correlate diet with lab results)
-- ============================================================================

CREATE VIEW v_3p_intake_vs_labs AS
SELECT
    u.id AS user_id,
    u.username,

    -- Last 7 days dietary intake (average per day)
    AVG(CASE WHEN DATE(m.meal_time) >= DATE('now', '-7 days') THEN mnc.protein_g_total END) AS avg_protein_last_7d,
    AVG(CASE WHEN DATE(m.meal_time) >= DATE('now', '-7 days') THEN mnc.potassium_mg_total END) AS avg_potassium_last_7d,
    AVG(CASE WHEN DATE(m.meal_time) >= DATE('now', '-7 days') THEN mnc.phosphorus_mg_total END) AS avg_phosphorus_last_7d,

    -- Latest lab values
    (SELECT potassium_value FROM potassium_logs WHERE user_id = u.id ORDER BY measured_at DESC LIMIT 1) AS latest_k,
    (SELECT phosphorus_mg_dl FROM phosphorus_logs WHERE user_id = u.id ORDER BY measured_at DESC LIMIT 1) AS latest_p,
    (SELECT creatinine_mg_dl FROM creatinine_egfr_logs WHERE user_id = u.id ORDER BY measured_at DESC LIMIT 1) AS latest_cr,
    (SELECT egfr_ml_min FROM creatinine_egfr_logs WHERE user_id = u.id ORDER BY measured_at DESC LIMIT 1) AS latest_egfr,

    -- Lab measurement dates
    (SELECT measured_at FROM potassium_logs WHERE user_id = u.id ORDER BY measured_at DESC LIMIT 1) AS k_lab_date,
    (SELECT measured_at FROM phosphorus_logs WHERE user_id = u.id ORDER BY measured_at DESC LIMIT 1) AS p_lab_date,
    (SELECT measured_at FROM creatinine_egfr_logs WHERE user_id = u.id ORDER BY measured_at DESC LIMIT 1) AS egfr_lab_date,

    -- K+ clearance analysis (high intake + normal K+ = good clearance)
    CASE
        -- Good dialysis clearance: high K intake but normal K lab
        WHEN AVG(CASE WHEN DATE(m.meal_time) >= DATE('now', '-7 days') THEN mnc.potassium_mg_total END) > 3000
         AND (SELECT potassium_value FROM potassium_logs WHERE user_id = u.id ORDER BY measured_at DESC LIMIT 1) < 5.0
        THEN 'GOOD_CLEARANCE'

        -- Poor K clearance: low K intake but high K lab (retention problem)
        WHEN AVG(CASE WHEN DATE(m.meal_time) >= DATE('now', '-7 days') THEN mnc.potassium_mg_total END) < 2000
         AND (SELECT potassium_value FROM potassium_logs WHERE user_id = u.id ORDER BY measured_at DESC LIMIT 1) > 5.5
        THEN 'POOR_CLEARANCE'

        -- Expected: K intake matches K lab
        ELSE 'NORMAL'
    END AS k_clearance_status,

    -- P clearance analysis
    CASE
        -- Good P clearance: moderate P intake but normal P lab
        WHEN AVG(CASE WHEN DATE(m.meal_time) >= DATE('now', '-7 days') THEN mnc.phosphorus_mg_total END) > 1000
         AND (SELECT phosphorus_mg_dl FROM phosphorus_logs WHERE user_id = u.id ORDER BY measured_at DESC LIMIT 1) < 4.5
        THEN 'GOOD_CLEARANCE'

        -- Poor P clearance: low P intake but high P lab
        WHEN AVG(CASE WHEN DATE(m.meal_time) >= DATE('now', '-7 days') THEN mnc.phosphorus_mg_total END) < 800
         AND (SELECT phosphorus_mg_dl FROM phosphorus_logs WHERE user_id = u.id ORDER BY measured_at DESC LIMIT 1) > 5.5
        THEN 'POOR_CLEARANCE'

        ELSE 'NORMAL'
    END AS p_clearance_status,

    -- Compliance score (dietary intake within targets)
    CASE
        WHEN AVG(CASE WHEN DATE(m.meal_time) >= DATE('now', '-7 days') THEN mnc.protein_g_total END) < 60
         AND AVG(CASE WHEN DATE(m.meal_time) >= DATE('now', '-7 days') THEN mnc.potassium_mg_total END) < 3000
         AND AVG(CASE WHEN DATE(m.meal_time) >= DATE('now', '-7 days') THEN mnc.phosphorus_mg_total END) < 1000
        THEN 'COMPLIANT'
        ELSE 'NON_COMPLIANT'
    END AS dietary_compliance

FROM users u
JOIN meals m ON u.id = m.user_id
JOIN meal_nutrition_calculations mnc ON m.id = mnc.meal_id
WHERE DATE(m.meal_time) >= DATE('now', '-30 days')
GROUP BY u.id;

-- ============================================================================
-- MONTHLY 3P SUMMARY VIEW
-- ============================================================================

CREATE VIEW v_monthly_3p_summary AS
SELECT
    user_id,
    strftime('%Y-%m', meal_time) AS month,
    strftime('%Y', meal_time) AS year,
    strftime('%m', meal_time) AS month_number,

    -- Monthly averages
    AVG(daily_protein_g) AS avg_daily_protein_g,
    AVG(daily_potassium_mg) AS avg_daily_potassium_mg,
    AVG(daily_phosphorus_mg) AS avg_daily_phosphorus_mg,
    AVG(daily_pral) AS avg_daily_pral,

    -- Monthly min/max (detect variability)
    MIN(daily_protein_g) AS min_daily_protein_g,
    MAX(daily_protein_g) AS max_daily_protein_g,
    MIN(daily_potassium_mg) AS min_daily_potassium_mg,
    MAX(daily_potassium_mg) AS max_daily_potassium_mg,
    MIN(daily_phosphorus_mg) AS min_daily_phosphorus_mg,
    MAX(daily_phosphorus_mg) AS max_daily_phosphorus_mg,

    -- Variability (high variability = inconsistent diet)
    MAX(daily_potassium_mg) - MIN(daily_potassium_mg) AS potassium_variability,
    MAX(daily_phosphorus_mg) - MIN(daily_phosphorus_mg) AS phosphorus_variability,

    -- Days logged in month
    COUNT(DISTINCT DATE(meal_time)) AS days_logged,

    -- Month-over-month change
    LAG(AVG(daily_protein_g)) OVER (PARTITION BY user_id ORDER BY strftime('%Y-%m', meal_time)) AS prev_month_protein,
    LAG(AVG(daily_potassium_mg)) OVER (PARTITION BY user_id ORDER BY strftime('%Y-%m', meal_time)) AS prev_month_potassium,
    LAG(AVG(daily_phosphorus_mg)) OVER (PARTITION BY user_id ORDER BY strftime('%Y-%m', meal_time)) AS prev_month_phosphorus

FROM (
    SELECT
        u.id AS user_id,
        m.meal_time,
        DATE(m.meal_time) AS date,
        SUM(mnc.protein_g_total) AS daily_protein_g,
        SUM(mnc.potassium_mg_total) AS daily_potassium_mg,
        SUM(mnc.phosphorus_mg_total) AS daily_phosphorus_mg,
        SUM(mnc.pral_value) AS daily_pral
    FROM users u
    JOIN meals m ON u.id = m.user_id
    JOIN meal_nutrition_calculations mnc ON m.id = mnc.meal_id
    WHERE mnc.protein_g_total IS NOT NULL
    GROUP BY u.id, DATE(m.meal_time)
)
GROUP BY user_id, strftime('%Y-%m', meal_time);

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check weekly trends view
SELECT
    'View v_weekly_3p_trends created' AS status,
    COUNT(*) AS sample_row_count
FROM v_weekly_3p_trends
LIMIT 1;

-- Check intake vs labs view
SELECT
    'View v_3p_intake_vs_labs created' AS status,
    COUNT(*) AS users_with_data
FROM v_3p_intake_vs_labs;

-- Check monthly summary view
SELECT
    'View v_monthly_3p_summary created' AS status,
    COUNT(*) AS sample_row_count
FROM v_monthly_3p_summary
LIMIT 1;
