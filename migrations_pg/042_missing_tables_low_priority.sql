-- Migration 042: Missing Tables - LOW PRIORITY
-- Social features, commerce platform, research capabilities, and infrastructure
-- Created: 2026-04-12
-- Tables: 41+ (Modules 4, 8, 9, 12, 13, 14, 15, 16, 17)

-- ============================================================================
-- MODULE 4: USER SYSTEM - Enhancement Tables (5 tables)
-- ============================================================================

-- User Stats - Aggregated user statistics (distinct from archive)
CREATE TABLE IF NOT EXISTS user_stats (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE,
    total_meals_logged INTEGER DEFAULT 0,
    total_foods_tried INTEGER DEFAULT 0,
    total_recipes_created INTEGER DEFAULT 0,
    streak_days INTEGER DEFAULT 0,
    longest_streak_days INTEGER DEFAULT 0,
    points_earned INTEGER DEFAULT 0,
    achievements_unlocked INTEGER DEFAULT 0,
    consultations_completed INTEGER DEFAULT 0,
    medications_tracked INTEGER DEFAULT 0,
    avg_adherence_rate DOUBLE PRECISION,
    last_activity_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_user_stats_streak ON user_stats(streak_days);
CREATE INDEX idx_user_stats_points ON user_stats(points_earned);

-- User Auth Tokens - JWT tokens and sessions
CREATE TABLE IF NOT EXISTS user_auth_tokens (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    token_type VARCHAR(20),        -- access / refresh / reset_password
    device_id VARCHAR(120),
    device_name VARCHAR(120),
    ip_address VARCHAR(45),
    user_agent TEXT,
    expires_at TIMESTAMP NOT NULL,
    revoked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_auth_token_user ON user_auth_tokens(user_id);
CREATE INDEX idx_auth_token_expires ON user_auth_tokens(expires_at);
CREATE INDEX idx_auth_token_revoked ON user_auth_tokens(revoked);

-- User Login History - Track login attempts and sessions
CREATE TABLE IF NOT EXISTS user_login_history (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    email VARCHAR(120),
    login_status VARCHAR(20),      -- success / failed / blocked
    failure_reason VARCHAR(60),
    ip_address VARCHAR(45),
    user_agent TEXT,
    device_type VARCHAR(40),       -- mobile / tablet / desktop
    location_country VARCHAR(60),
    location_city VARCHAR(60),
    login_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_login_history_user ON user_login_history(user_id);
CREATE INDEX idx_login_history_status ON user_login_history(login_status);
CREATE INDEX idx_login_history_time ON user_login_history(login_at);

-- User Devices - Registered devices per user
CREATE TABLE IF NOT EXISTS user_devices (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    device_id VARCHAR(120) NOT NULL,
    device_name VARCHAR(120),
    device_type VARCHAR(40),       -- ios / android / web / desktop
    os_version VARCHAR(60),
    app_version VARCHAR(40),
    push_token VARCHAR(255),       -- For notifications
    is_active BOOLEAN DEFAULT TRUE,
    last_seen_at TIMESTAMP,
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id, device_id)
);

CREATE INDEX idx_user_device_user ON user_devices(user_id);
CREATE INDEX idx_user_device_active ON user_devices(is_active);

-- User Referrals - Referral tracking system
CREATE TABLE IF NOT EXISTS user_referrals (
    id SERIAL PRIMARY KEY,
    referrer_user_id INTEGER NOT NULL,
    referred_user_id INTEGER,
    referral_code VARCHAR(40) UNIQUE NOT NULL,
    referral_status VARCHAR(20),   -- pending / signed_up / active / rewarded
    referred_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    signed_up_at TIMESTAMP,
    reward_points_earned INTEGER DEFAULT 0,
    notes TEXT,
    FOREIGN KEY (referrer_user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (referred_user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_referral_referrer ON user_referrals(referrer_user_id);
CREATE INDEX idx_referral_referred ON user_referrals(referred_user_id);
CREATE INDEX idx_referral_code ON user_referrals(referral_code);

-- ============================================================================
-- MODULE 8: FACILITY PARTNERSHIPS - Enhancement Tables (8 tables)
-- ============================================================================

-- Facility Services - Services offered by each facility
CREATE TABLE IF NOT EXISTS facility_services (
    id SERIAL PRIMARY KEY,
    facility_id INTEGER NOT NULL,
    service_name VARCHAR(120) NOT NULL,
    service_type VARCHAR(40),      -- lab / imaging / consultation / procedure / pharmacy
    description TEXT,
    price_ugx DOUBLE PRECISION,
    duration_minutes INTEGER,
    afya_points_earned INTEGER,
    requires_appointment BOOLEAN DEFAULT FALSE,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (facility_id) REFERENCES facility_partners(id) ON DELETE CASCADE
);

CREATE INDEX idx_facility_service_facility ON facility_services(facility_id);
CREATE INDEX idx_facility_service_type ON facility_services(service_type);

-- Facility Locations - Additional location details beyond partner record
CREATE TABLE IF NOT EXISTS facility_locations (
    id SERIAL PRIMARY KEY,
    facility_id INTEGER NOT NULL,
    location_name VARCHAR(120),
    is_main_branch BOOLEAN DEFAULT FALSE,
    address TEXT,
    district VARCHAR(60),
    region VARCHAR(60),
    gps_lat DOUBLE PRECISION,
    gps_lng DOUBLE PRECISION,
    phone VARCHAR(20),
    email VARCHAR(120),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (facility_id) REFERENCES facility_partners(id) ON DELETE CASCADE
);

CREATE INDEX idx_facility_location_facility ON facility_locations(facility_id);
CREATE INDEX idx_facility_location_active ON facility_locations(is_active);

-- Facility Operating Hours - Hours per facility location
CREATE TABLE IF NOT EXISTS facility_operating_hours (
    id SERIAL PRIMARY KEY,
    facility_id INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL, -- 0=Sunday, 6=Saturday
    opens_at TIME,
    closes_at TIME,
    is_24_hours BOOLEAN DEFAULT FALSE,
    is_closed BOOLEAN DEFAULT FALSE,
    notes TEXT,
    FOREIGN KEY (facility_id) REFERENCES facility_partners(id) ON DELETE CASCADE,
    UNIQUE(facility_id, day_of_week)
);

CREATE INDEX idx_facility_hours_facility ON facility_operating_hours(facility_id);

-- Facility Staff Mapping - Which staff work at which facilities
CREATE TABLE IF NOT EXISTS facility_staff_mapping (
    id SERIAL PRIMARY KEY,
    facility_id INTEGER NOT NULL,
    staff_id INTEGER NOT NULL,
    role_at_facility VARCHAR(60),
    start_date DATE,
    end_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (facility_id) REFERENCES facility_partners(id) ON DELETE CASCADE,
    FOREIGN KEY (staff_id) REFERENCES medical_staff(id) ON DELETE CASCADE,
    UNIQUE(facility_id, staff_id)
);

CREATE INDEX idx_facility_staff_facility ON facility_staff_mapping(facility_id);
CREATE INDEX idx_facility_staff_staff ON facility_staff_mapping(staff_id);

-- Facility Ratings - User reviews of facilities
CREATE TABLE IF NOT EXISTS facility_ratings (
    id SERIAL PRIMARY KEY,
    facility_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    overall_rating INTEGER NOT NULL, -- 1-5 stars
    cleanliness_rating INTEGER,
    staff_friendliness_rating INTEGER,
    wait_time_rating INTEGER,
    value_for_money_rating INTEGER,
    review_text TEXT,
    would_recommend BOOLEAN,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (facility_id) REFERENCES facility_partners(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_facility_rating_facility ON facility_ratings(facility_id);
CREATE INDEX idx_facility_rating_user ON facility_ratings(user_id);

-- Facility Certifications - Accreditations and certifications
CREATE TABLE IF NOT EXISTS facility_certifications (
    id SERIAL PRIMARY KEY,
    facility_id INTEGER NOT NULL,
    certification_name VARCHAR(120),
    issuing_body VARCHAR(120),
    certification_number VARCHAR(60),
    issue_date DATE,
    expiry_date DATE,
    status VARCHAR(20),            -- active / expired / suspended / revoked
    document_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (facility_id) REFERENCES facility_partners(id) ON DELETE CASCADE
);

CREATE INDEX idx_facility_cert_facility ON facility_certifications(facility_id);
CREATE INDEX idx_facility_cert_status ON facility_certifications(status);

-- Partnership Agreements - Contract details with facilities
CREATE TABLE IF NOT EXISTS partnership_agreements (
    id SERIAL PRIMARY KEY,
    facility_id INTEGER NOT NULL,
    agreement_type VARCHAR(40),    -- service / referral / exclusive / preferred
    start_date DATE NOT NULL,
    end_date DATE,
    commission_pct DOUBLE PRECISION,
    payment_terms VARCHAR(60),     -- weekly / monthly / per_transaction
    minimum_guarantee_ugx DOUBLE PRECISION,
    performance_bonuses TEXT,      -- JSON
    agreement_status VARCHAR(20),  -- draft / active / expired / terminated
    signed_by VARCHAR(120),
    document_url VARCHAR(500),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (facility_id) REFERENCES facility_partners(id) ON DELETE CASCADE
);

CREATE INDEX idx_partnership_facility ON partnership_agreements(facility_id);
CREATE INDEX idx_partnership_status ON partnership_agreements(agreement_status);

-- Facility Commission Log - Track commissions earned/paid
CREATE TABLE IF NOT EXISTS facility_commission_log (
    id SERIAL PRIMARY KEY,
    facility_id INTEGER NOT NULL,
    transaction_type VARCHAR(40),  -- consultation / lab_test / pharmacy_order / service
    transaction_id INTEGER,
    transaction_amount_ugx DOUBLE PRECISION NOT NULL,
    commission_pct DOUBLE PRECISION NOT NULL,
    commission_amount_ugx DOUBLE PRECISION NOT NULL,
    payment_status VARCHAR(20),    -- pending / paid / disputed
    payment_date DATE,
    payment_ref VARCHAR(120),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (facility_id) REFERENCES facility_partners(id) ON DELETE CASCADE
);

CREATE INDEX idx_commission_facility ON facility_commission_log(facility_id);
CREATE INDEX idx_commission_status ON facility_commission_log(payment_status);

-- ============================================================================
-- MODULE 9: LAB & DIAGNOSTICS - Enhancement Tables (8 tables)
-- ============================================================================

-- Lab Test Catalog - Available lab tests
CREATE TABLE IF NOT EXISTS lab_test_catalog (
    id SERIAL PRIMARY KEY,
    test_name VARCHAR(120) NOT NULL,
    test_code VARCHAR(40) UNIQUE,
    test_category VARCHAR(60),     -- chemistry / hematology / immunology / microbiology
    description TEXT,
    specimen_type VARCHAR(60),     -- blood / urine / stool / saliva
    specimen_volume VARCHAR(40),
    fasting_required BOOLEAN DEFAULT FALSE,
    turnaround_time_hours INTEGER,
    typical_price_ugx DOUBLE PRECISION,
    reference_ranges TEXT,         -- JSON by age/gender
    clinical_significance TEXT,
    preparation_instructions TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_lab_test_category ON lab_test_catalog(test_category);
CREATE INDEX idx_lab_test_code ON lab_test_catalog(test_code);

-- Imaging Results - X-ray, ultrasound, CT, MRI results
CREATE TABLE IF NOT EXISTS imaging_results (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    consultation_id INTEGER,
    imaging_type VARCHAR(40),      -- xray / ultrasound / ct_scan / mri / mammogram
    body_part VARCHAR(60),
    indication TEXT,               -- Why imaging ordered
    findings TEXT,
    impression TEXT,               -- Radiologist interpretation
    recommendations TEXT,
    image_urls TEXT,               -- JSON array
    performed_at TIMESTAMP,
    facility_id INTEGER,
    radiologist_name VARCHAR(120),
    is_normal BOOLEAN,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (consultation_id) REFERENCES consultations(id) ON DELETE SET NULL,
    FOREIGN KEY (facility_id) REFERENCES facility_partners(id) ON DELETE SET NULL
);

CREATE INDEX idx_imaging_user ON imaging_results(user_id);
CREATE INDEX idx_imaging_type ON imaging_results(imaging_type);
CREATE INDEX idx_imaging_date ON imaging_results(performed_at);

-- Biomarker Trends - Track biomarker changes over time
CREATE TABLE IF NOT EXISTS biomarker_trends (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    biomarker_name VARCHAR(60) NOT NULL,
    analysis_date DATE NOT NULL,
    period_days INTEGER DEFAULT 90,
    baseline_value DOUBLE PRECISION,
    latest_value DOUBLE PRECISION,
    change_amount DOUBLE PRECISION,
    change_pct DOUBLE PRECISION,
    trend VARCHAR(20),             -- improving / stable / worsening
    interpretation TEXT,
    clinical_action TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_biomarker_trend_user ON biomarker_trends(user_id);
CREATE INDEX idx_biomarker_trend_name ON biomarker_trends(biomarker_name);

-- Lab Reference Ranges - Normal ranges by age/gender
CREATE TABLE IF NOT EXISTS lab_reference_ranges (
    id SERIAL PRIMARY KEY,
    test_name VARCHAR(120) NOT NULL,
    age_min INTEGER,
    age_max INTEGER,
    gender VARCHAR(20),            -- male / female / any
    range_min DOUBLE PRECISION,
    range_max DOUBLE PRECISION,
    unit VARCHAR(40),
    interpretation_low TEXT,
    interpretation_normal TEXT,
    interpretation_high TEXT,
    source VARCHAR(120),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_lab_range_test ON lab_reference_ranges(test_name);
CREATE INDEX idx_lab_range_gender ON lab_reference_ranges(gender);

-- Test Interpretation Rules - Automated result interpretation
CREATE TABLE IF NOT EXISTS test_interpretation_rules (
    id SERIAL PRIMARY KEY,
    test_name VARCHAR(120) NOT NULL,
    rule_condition TEXT NOT NULL,  -- SQL-like condition
    interpretation TEXT,
    severity VARCHAR(20),          -- normal / borderline / abnormal / critical
    recommended_action TEXT,
    follow_up_test VARCHAR(120),
    consult_specialist VARCHAR(60),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_test_rule_test ON test_interpretation_rules(test_name);
CREATE INDEX idx_test_rule_severity ON test_interpretation_rules(severity);

-- Lab Orders - Track lab test orders
CREATE TABLE IF NOT EXISTS lab_orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    consultation_id INTEGER,
    facility_id INTEGER,
    test_ids TEXT,                 -- JSON array of lab_test_catalog IDs
    order_date DATE NOT NULL,
    collection_date DATE,
    result_date DATE,
    status VARCHAR(20),            -- ordered / collected / in_progress / completed / cancelled
    priority VARCHAR(20),          -- routine / urgent / stat
    fasting_status BOOLEAN,
    total_cost_ugx DOUBLE PRECISION,
    payment_status VARCHAR(20),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (consultation_id) REFERENCES consultations(id) ON DELETE SET NULL,
    FOREIGN KEY (facility_id) REFERENCES facility_partners(id) ON DELETE SET NULL
);

CREATE INDEX idx_lab_order_user ON lab_orders(user_id);
CREATE INDEX idx_lab_order_status ON lab_orders(status);
CREATE INDEX idx_lab_order_date ON lab_orders(order_date);

-- Specimen Tracking - Track specimen collection and processing
CREATE TABLE IF NOT EXISTS specimen_tracking (
    id SERIAL PRIMARY KEY,
    lab_order_id INTEGER NOT NULL,
    specimen_id VARCHAR(60) UNIQUE NOT NULL,
    specimen_type VARCHAR(60),
    collected_at TIMESTAMP,
    collected_by VARCHAR(120),
    received_at_lab TIMESTAMP,
    processing_started_at TIMESTAMP,
    processing_completed_at TIMESTAMP,
    status VARCHAR(20),            -- collected / in_transit / received / processing / completed / rejected
    rejection_reason TEXT,
    quality_check_passed BOOLEAN,
    notes TEXT,
    FOREIGN KEY (lab_order_id) REFERENCES lab_orders(id) ON DELETE CASCADE
);

CREATE INDEX idx_specimen_order ON specimen_tracking(lab_order_id);
CREATE INDEX idx_specimen_id ON specimen_tracking(specimen_id);
CREATE INDEX idx_specimen_status ON specimen_tracking(status);

-- Diagnostic Alerts - Critical result notifications
CREATE TABLE IF NOT EXISTS diagnostic_alerts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    diagnostic_result_id INTEGER,
    alert_type VARCHAR(40),        -- critical_value / trend_warning / screening_due
    severity VARCHAR(20),          -- info / warning / critical
    alert_message TEXT NOT NULL,
    recommended_action TEXT,
    acknowledged BOOLEAN DEFAULT FALSE,
    acknowledged_by INTEGER,
    acknowledged_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (diagnostic_result_id) REFERENCES diagnostic_results(id) ON DELETE SET NULL,
    FOREIGN KEY (acknowledged_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_diagnostic_alert_user ON diagnostic_alerts(user_id);
CREATE INDEX idx_diagnostic_alert_severity ON diagnostic_alerts(severity);
CREATE INDEX idx_diagnostic_alert_ack ON diagnostic_alerts(acknowledged);

-- ============================================================================
-- MODULE 12: AI ENGINE - Enhancement Tables (8 tables)
-- ============================================================================

-- AI Model Registry - Track deployed AI models
CREATE TABLE IF NOT EXISTS ai_model_registry (
    id SERIAL PRIMARY KEY,
    model_name VARCHAR(120) NOT NULL UNIQUE,
    model_type VARCHAR(60),        -- recommendation / prediction / classification / nlp
    model_version VARCHAR(40) NOT NULL,
    description TEXT,
    input_features TEXT,           -- JSON array
    output_format TEXT,
    accuracy_score DOUBLE PRECISION,
    f1_score DOUBLE PRECISION,
    training_date DATE,
    deployed_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    endpoint_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ai_model_type ON ai_model_registry(model_type);
CREATE INDEX idx_ai_model_active ON ai_model_registry(is_active);

-- AI Recommendation Types - Categories of recommendations
CREATE TABLE IF NOT EXISTS ai_recommendation_types (
    id SERIAL PRIMARY KEY,
    type_name VARCHAR(60) NOT NULL UNIQUE,
    category VARCHAR(40),          -- food / exercise / medication / screening / lifestyle
    description TEXT,
    model_id INTEGER,
    priority_weight DOUBLE PRECISION DEFAULT 1.0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (model_id) REFERENCES ai_model_registry(id) ON DELETE SET NULL
);

CREATE INDEX idx_ai_rec_type_category ON ai_recommendation_types(category);

-- AI Inference Results - Raw model predictions
CREATE TABLE IF NOT EXISTS ai_inference_results (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    model_id INTEGER NOT NULL,
    input_data TEXT,               -- JSON
    output_data TEXT,              -- JSON
    confidence_score DOUBLE PRECISION,
    inference_time_ms INTEGER,
    inference_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (model_id) REFERENCES ai_model_registry(id) ON DELETE CASCADE
);

CREATE INDEX idx_ai_inference_user ON ai_inference_results(user_id);
CREATE INDEX idx_ai_inference_model ON ai_inference_results(model_id);
CREATE INDEX idx_ai_inference_time ON ai_inference_results(inference_at);

-- Recommendation Feedback - User response to recommendations
CREATE TABLE IF NOT EXISTS recommendation_feedback (
    id SERIAL PRIMARY KEY,
    recommendation_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    feedback_type VARCHAR(20),     -- accepted / dismissed / deferred / completed
    feedback_rating INTEGER,       -- 1-5 stars
    feedback_text TEXT,
    was_helpful BOOLEAN,
    reason_dismissed TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (recommendation_id) REFERENCES ai_recommendations(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_rec_feedback_rec ON recommendation_feedback(recommendation_id);
CREATE INDEX idx_rec_feedback_user ON recommendation_feedback(user_id);
CREATE INDEX idx_rec_feedback_type ON recommendation_feedback(feedback_type);

-- Anomaly Detection Logs - Unusual patterns flagged by AI
CREATE TABLE IF NOT EXISTS anomaly_detection_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    anomaly_type VARCHAR(60),      -- nutrition / biometric / medication / activity
    metric_name VARCHAR(60),
    expected_value DOUBLE PRECISION,
    actual_value DOUBLE PRECISION,
    deviation_score DOUBLE PRECISION,
    severity VARCHAR(20),          -- minor / moderate / significant / critical
    explanation TEXT,
    recommended_action TEXT,
    reviewed_by_staff BOOLEAN DEFAULT FALSE,
    detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_anomaly_user ON anomaly_detection_logs(user_id);
CREATE INDEX idx_anomaly_severity ON anomaly_detection_logs(severity);
CREATE INDEX idx_anomaly_type ON anomaly_detection_logs(anomaly_type);

-- Automated Nudge History - AI-triggered notifications
CREATE TABLE IF NOT EXISTS automated_nudge_history (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    nudge_type VARCHAR(60),        -- meal_reminder / water_reminder / medication_reminder / activity_prompt
    trigger_condition TEXT,
    message_sent TEXT,
    delivery_method VARCHAR(20),   -- push / sms / email / in_app
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    opened BOOLEAN DEFAULT FALSE,
    opened_at TIMESTAMP,
    action_taken BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_nudge_user ON automated_nudge_history(user_id);
CREATE INDEX idx_nudge_type ON automated_nudge_history(nudge_type);
CREATE INDEX idx_nudge_opened ON automated_nudge_history(opened);

-- Personalization Params - User-specific ML parameters
CREATE TABLE IF NOT EXISTS personalization_params (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE,
    food_preference_vector TEXT,   -- JSON embedding
    health_priority_weights TEXT,  -- JSON
    engagement_score DOUBLE PRECISION,
    response_rate_pct DOUBLE PRECISION,
    optimal_notification_time TIME,
    preferred_recommendation_types TEXT, -- JSON array
    learning_rate DOUBLE PRECISION,
    last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_personalization_user ON personalization_params(user_id);

-- Behavioral Segmentation - User behavior clusters
CREATE TABLE IF NOT EXISTS behavioral_segmentation (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    segment_name VARCHAR(60),      -- engaged_tracker / sporadic_user / health_focused / social_user
    segment_score DOUBLE PRECISION,
    engagement_level VARCHAR(20),  -- high / medium / low
    health_literacy VARCHAR(20),   -- high / medium / low
    digital_savviness VARCHAR(20), -- high / medium / low
    risk_tolerance VARCHAR(20),    -- high / medium / low
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_until TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_behavior_user ON behavioral_segmentation(user_id);
CREATE INDEX idx_behavior_segment ON behavioral_segmentation(segment_name);

-- ============================================================================
-- REMAINING MODULES (13, 14, 15, 16, 17) - TO BE CONTINUED IN MIGRATION 043
-- ============================================================================
