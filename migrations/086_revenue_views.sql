-- Migration 086: Fee Structure Expansion + Revenue Views
-- Financial reporting and analytics

-- ============================================================================
-- VIEW: DAILY PLATFORM REVENUE
-- ============================================================================

CREATE VIEW IF NOT EXISTS v_daily_platform_revenue AS
SELECT
    revenue_date,
    SUM(CASE WHEN revenue_source = 'consultation_commission' THEN amount_ugx ELSE 0 END) AS consultation_revenue_ugx,
    SUM(CASE WHEN revenue_source = 'referral_fee' THEN amount_ugx ELSE 0 END) AS referral_revenue_ugx,
    SUM(CASE WHEN revenue_source = 'subscription' THEN amount_ugx ELSE 0 END) AS subscription_revenue_ugx,
    SUM(CASE WHEN revenue_source = 'lab_commission' THEN amount_ugx ELSE 0 END) AS lab_revenue_ugx,
    SUM(CASE WHEN revenue_source = 'pharmacy_commission' THEN amount_ugx ELSE 0 END) AS pharmacy_revenue_ugx,
    SUM(CASE WHEN revenue_source = 'premium_purchase' THEN amount_ugx ELSE 0 END) AS premium_purchase_revenue_ugx,
    SUM(amount_ugx) AS total_revenue_ugx,
    SUM(amount_local_currency) AS total_revenue_local,
    COUNT(*) AS transaction_count
FROM platform_revenue_ledger
GROUP BY revenue_date
ORDER BY revenue_date DESC;

-- ============================================================================
-- VIEW: PARTNER PERFORMANCE DASHBOARD
-- ============================================================================

CREATE VIEW IF NOT EXISTS v_partner_performance_dashboard AS
SELECT
    pc.id AS contract_id,
    pc.partner_name,
    pc.partner_type,
    pc.commission_rate_pct,
    pc.contract_status,
    ppm.metric_month,
    ppm.total_transactions,
    ppm.total_revenue_ugx,
    ppm.platform_commission_ugx,
    ppm.partner_payout_ugx,
    ppm.average_rating,
    ppm.total_reviews,
    ppm.complaint_count,
    ppm.average_response_time_minutes,
    ppm.cancellation_rate_pct,
    ppm.performance_grade,
    CASE
        WHEN ppm.average_rating >= 4.5 AND ppm.cancellation_rate_pct < 2 THEN 'EXCELLENT'
        WHEN ppm.average_rating >= 4.0 AND ppm.cancellation_rate_pct < 5 THEN 'GOOD'
        WHEN ppm.average_rating >= 3.5 THEN 'AVERAGE'
        WHEN ppm.average_rating >= 3.0 THEN 'BELOW_AVERAGE'
        ELSE 'POOR'
    END AS partner_health_status
FROM partner_contracts pc
LEFT JOIN partner_performance_metrics ppm ON pc.id = ppm.contract_id
WHERE pc.contract_status = 'active';

-- ============================================================================
-- VIEW: SUBSCRIPTION ANALYTICS
-- ============================================================================

CREATE VIEW IF NOT EXISTS v_subscription_analytics AS
SELECT
    sp.id AS plan_id,
    sp.plan_name,
    sp.tier,
    sp.price_monthly_ugx,
    sp.price_monthly_usd,
    COUNT(us.id) AS total_subscribers,
    SUM(CASE WHEN us.status = 'active' THEN 1 ELSE 0 END) AS active_subscribers,
    SUM(CASE WHEN us.status = 'trial' THEN 1 ELSE 0 END) AS trial_users,
    SUM(CASE WHEN us.status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled_subscribers,
    SUM(CASE WHEN us.status = 'expired' THEN 1 ELSE 0 END) AS expired_subscribers,
    -- Monthly Recurring Revenue
    SUM(CASE WHEN us.status = 'active' AND us.billing_cycle = 'monthly' THEN sp.price_monthly_ugx ELSE 0 END) AS mrr_monthly_ugx,
    SUM(CASE WHEN us.status = 'active' AND us.billing_cycle = 'annual' THEN sp.price_annual_ugx / 12.0 ELSE 0 END) AS mrr_annual_ugx,
    SUM(CASE WHEN us.status = 'active' THEN
        CASE WHEN us.billing_cycle = 'monthly' THEN sp.price_monthly_ugx
             ELSE sp.price_annual_ugx / 12.0 END
    ELSE 0 END) AS total_mrr_ugx,
    -- Annual Run Rate
    SUM(CASE WHEN us.status = 'active' THEN
        CASE WHEN us.billing_cycle = 'monthly' THEN sp.price_monthly_ugx * 12
             ELSE sp.price_annual_ugx END
    ELSE 0 END) AS arr_ugx
FROM subscription_plans sp
LEFT JOIN user_subscriptions us ON sp.id = us.plan_id
GROUP BY sp.id;

-- ============================================================================
-- VIEW: CONSULTATION REVENUE BREAKDOWN
-- ============================================================================

CREATE VIEW IF NOT EXISTS v_consultation_revenue_breakdown AS
SELECT
    dp.specialty_id,
    ms.specialty_name,
    cb.consultation_type,
    COUNT(cb.id) AS total_bookings,
    SUM(CASE WHEN cb.status = 'completed' THEN 1 ELSE 0 END) AS completed_bookings,
    SUM(CASE WHEN cb.status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled_bookings,
    SUM(cb.consultation_fee_ugx) AS gross_revenue_ugx,
    SUM(cb.platform_commission_ugx) AS platform_revenue_ugx,
    SUM(cb.doctor_payout_ugx) AS doctor_payout_ugx,
    AVG(cb.consultation_fee_ugx) AS avg_consultation_fee_ugx,
    AVG(cb.platform_commission_pct) AS avg_commission_pct
FROM consultation_bookings cb
JOIN doctor_profiles dp ON cb.doctor_profile_id = dp.id
JOIN medical_specialties ms ON dp.specialty_id = ms.id
WHERE cb.status IN ('completed', 'in_progress')
GROUP BY dp.specialty_id, cb.consultation_type;

-- ============================================================================
-- VIEW: USER COMPLETE PROFILE (user + subscription + conditions + game stats)
-- ============================================================================

CREATE VIEW IF NOT EXISTS v_user_complete_profile AS
SELECT
    u.id AS user_id,
    u.username,
    u.email,
    u.has_completed_health_declaration,

    -- Subscription info
    sp.plan_name AS subscription_plan,
    sp.tier AS subscription_tier,
    us.status AS subscription_status,
    us.current_period_end AS subscription_expires,

    -- Primary condition
    mc.condition_name AS primary_condition,
    mc.category AS condition_category,
    uc.severity,
    uc.stage AS condition_stage,

    -- Game stats
    avs.level,
    avs.current_xp,
    avs.current_streak,
    avs.afya_points_balance,

    -- Activity
    u.last_login

FROM users u
LEFT JOIN user_subscriptions us ON u.id = us.user_id AND us.status IN ('active', 'trial')
LEFT JOIN subscription_plans sp ON us.plan_id = sp.id
LEFT JOIN user_conditions uc ON u.id = uc.user_id AND uc.is_primary = TRUE AND uc.status = 'active'
LEFT JOIN medical_conditions mc ON uc.condition_id = mc.id
LEFT JOIN avatar_stats avs ON u.id = avs.user_id;

-- ============================================================================
-- VIEW: PLATFORM HEALTH SUMMARY
-- ============================================================================

CREATE VIEW IF NOT EXISTS v_platform_health_summary AS
SELECT
    (SELECT COUNT(*) FROM users) AS total_users,
    (SELECT COUNT(*) FROM user_subscriptions WHERE status = 'active') AS active_subscribers,
    (SELECT COUNT(*) FROM user_subscriptions WHERE status = 'active' AND plan_id = 2) AS plus_subscribers,
    (SELECT COUNT(*) FROM user_subscriptions WHERE status = 'active' AND plan_id = 3) AS pro_subscribers,
    (SELECT COUNT(*) FROM partner_contracts WHERE contract_status = 'active') AS active_partners,
    (SELECT COUNT(*) FROM doctor_profiles WHERE is_active = TRUE) AS active_doctors,
    (SELECT COUNT(*) FROM consultation_bookings WHERE status = 'completed') AS total_consultations,
    (SELECT COALESCE(SUM(platform_commission_ugx), 0) FROM consultation_bookings WHERE status = 'completed') AS total_consultation_revenue_ugx,
    (SELECT COALESCE(SUM(amount_ugx), 0) FROM platform_revenue_ledger) AS total_platform_revenue_ugx,
    (SELECT COUNT(*) FROM guilds WHERE is_active = TRUE) AS active_guilds,
    (SELECT COUNT(*) FROM user_pets WHERE is_active = TRUE) AS active_pets,
    (SELECT COUNT(*) FROM user_boss_progress WHERE status = 'defeated') AS total_boss_defeats;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT 'v_daily_platform_revenue' AS view_name, 'created' AS status
UNION ALL
SELECT 'v_partner_performance_dashboard', 'created'
UNION ALL
SELECT 'v_subscription_analytics', 'created'
UNION ALL
SELECT 'v_consultation_revenue_breakdown', 'created'
UNION ALL
SELECT 'v_user_complete_profile', 'created'
UNION ALL
SELECT 'v_platform_health_summary', 'created';
