-- Migration 054: Diabetes Biomarker Tracking
-- Creates dedicated tables for blood glucose monitoring and glycemic control
-- Part of Medical Core Infrastructure (Phase 1)

-- ============================================================================
-- FASTING BLOOD SUGAR (FBS) TRACKING
-- ============================================================================
-- Gold standard for diabetes diagnosis and monitoring
-- Normal: <100 mg/dL
-- Prediabetes: 100-125 mg/dL
-- Diabetes: ≥126 mg/dL (confirmed on 2+ occasions)
-- Target for diabetics: 80-130 mg/dL

CREATE TABLE fasting_blood_sugar_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,

    -- Measurement data
    fbs_mg_dl DOUBLE PRECISION NOT NULL,
    measured_at TIMESTAMP NOT NULL,
    measurement_method VARCHAR(50),  -- glucometer / lab / cgm (continuous glucose monitor)

    -- Fasting validation
    fasting_hours INTEGER,  -- How long fasted (minimum 8 hours for valid FBS)
    last_meal_time TIMESTAMP,  -- When did they last eat?

    -- Context (critical for interpretation)
    previous_meal_logged BOOLEAN DEFAULT FALSE,  -- Did user log dinner before this FBS?
    medication_taken BOOLEAN DEFAULT FALSE,  -- Did user take diabetic meds as prescribed?
    medication_time TIMESTAMP,  -- When did they take medication?
    illness_status VARCHAR(100),  -- Sick, stressed, menstruating (affects glucose)

    -- Clinical interpretation
    control_category VARCHAR(20),  -- excellent / good / fair / poor / very_poor
    is_diagnostic BOOLEAN DEFAULT FALSE,  -- Part of formal diagnosis?
    requires_action BOOLEAN DEFAULT FALSE,  -- Immediate intervention needed?

    -- Symptoms at time of reading
    symptoms TEXT,  -- Shakiness, sweating, confusion (hypoglycemia), excessive thirst (hyperglycemia)

    -- Audit
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    entered_by INTEGER,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (entered_by) REFERENCES users(id)
);

CREATE INDEX idx_fbs_logs_user_date ON fasting_blood_sugar_logs(user_id, measured_at DESC);
CREATE INDEX idx_fbs_logs_control ON fasting_blood_sugar_logs(control_category, measured_at DESC);


-- ============================================================================
-- RANDOM BLOOD SUGAR (RBS) TRACKING
-- ============================================================================
-- Post-meal glucose monitoring (most common for daily tracking)
-- Normal: <140 mg/dL (2 hours post-meal)
-- Prediabetes: 140-199 mg/dL
-- Diabetes: ≥200 mg/dL
-- Target for diabetics: <180 mg/dL (2 hours post-meal)

CREATE TABLE random_blood_sugar_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,

    -- Measurement data
    rbs_mg_dl DOUBLE PRECISION NOT NULL,
    measured_at TIMESTAMP NOT NULL,
    measurement_method VARCHAR(50),

    -- Meal context (CRITICAL for interpretation)
    hours_since_meal DOUBLE PRECISION,  -- Time since last meal (key variable)
    meal_id INTEGER,  -- Link to what they ate (enables correlation analysis)
    meal_carbs_g DOUBLE PRECISION,  -- Carbs in that meal (if available)
    meal_glycemic_load DOUBLE PRECISION,  -- GL of that meal (if calculated)

    -- Activity context
    physical_activity VARCHAR(50),  -- rest / light_activity / moderate / intense
    activity_duration_min INTEGER,  -- How long were they active?

    -- Psychological context
    stress_level INTEGER,  -- 1-10 scale (stress raises glucose)
    sleep_quality INTEGER,  -- 1-10 scale (poor sleep affects control)

    -- Symptoms
    symptoms TEXT,  -- hypoglycemia (shaking, sweating, confusion) or hyperglycemia (thirst, urination)

    -- Clinical interpretation
    control_category VARCHAR(20),
    requires_action BOOLEAN DEFAULT FALSE,

    -- Audit
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    entered_by INTEGER,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (meal_id) REFERENCES meals(id),
    FOREIGN KEY (entered_by) REFERENCES users(id)
);

CREATE INDEX idx_rbs_logs_user_date ON random_blood_sugar_logs(user_id, measured_at DESC);
CREATE INDEX idx_rbs_logs_meal ON random_blood_sugar_logs(meal_id, measured_at DESC);


-- ============================================================================
-- HbA1c TRACKING (Glycated Hemoglobin)
-- ============================================================================
-- 3-month average of blood glucose (gold standard for long-term control)
-- Normal: <5.7%
-- Prediabetes: 5.7-6.4%
-- Diabetes: ≥6.5% (diagnostic)
-- Target for diabetics: <7.0% (ADA guideline), <6.5% for tight control

CREATE TABLE hba1c_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,

    -- Measurement data
    hba1c_percent DOUBLE PRECISION NOT NULL,
    measured_at TIMESTAMP NOT NULL,
    lab_facility_id INTEGER,

    -- Derived metrics
    estimated_avg_glucose_mg_dl DOUBLE PRECISION,  -- eAG formula: (HbA1c × 28.7) - 46.7

    -- Clinical interpretation
    control_category VARCHAR(20),  -- excellent (<5.7) / good (5.7-6.4) / fair (6.5-7.9) / poor (8.0-9.9) / very_poor (≥10)
    diabetes_risk VARCHAR(20),  -- normal / prediabetes / diabetes / uncontrolled_diabetes
    is_diagnostic BOOLEAN DEFAULT FALSE,  -- Used for formal diagnosis?

    -- Trend tracking (critical for patient motivation and gamification)
    previous_hba1c DOUBLE PRECISION,  -- Previous reading for comparison
    previous_test_date DATE,  -- When was previous test?
    change_from_previous DOUBLE PRECISION,  -- Positive = worsening, Negative = improving
    change_percent DOUBLE PRECISION,  -- Percentage change
    trend VARCHAR(20),  -- improving / stable / worsening

    -- Risk assessment
    cardiovascular_risk VARCHAR(20),  -- low / medium / high / very_high
    microvascular_risk VARCHAR(20),  -- Risk of eye, kidney, nerve damage

    -- Context
    treatment_changes TEXT,  -- Did medication/diet change between tests?
    adherence_estimate INTEGER,  -- 1-100% estimated medication/diet adherence

    -- Audit
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    entered_by INTEGER,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (lab_facility_id) REFERENCES partner_facilities(id),
    FOREIGN KEY (entered_by) REFERENCES users(id)
);

CREATE INDEX idx_hba1c_logs_user_date ON hba1c_logs(user_id, measured_at DESC);
CREATE INDEX idx_hba1c_logs_trend ON hba1c_logs(trend, measured_at DESC);


-- ============================================================================
-- CLINICAL NOTES
-- ============================================================================
-- Diabetes management through Vurafya:
--
-- 1. **Daily Monitoring** (FBS + RBS):
--    - User logs FBS every morning → App checks if medication taken
--    - User logs meals → App calculates glycemic load
--    - User logs RBS 2 hours post-meal → App correlates with meal GL
--    - Pattern detection: High-GL meals → High RBS (educate user)
--
-- 2. **Meal Recommendations**:
--    - IF FBS high (>130) THEN recommend low-GL breakfast
--    - IF RBS spike after rice THEN suggest brown rice or smaller portion
--    - IF HbA1c worsening THEN tighten carb targets
--
-- 3. **Gamification Integration**:
--    - XP for logging FBS daily (adherence streak)
--    - Milestone: HbA1c drops 0.5% → 200 XP + avatar evolution
--    - Milestone: FBS in target range 7 days straight → 100 XP + badge
--    - Competition: Lowest average RBS spike wins (motivates low-GL eating)
--
-- 4. **Health Scoring**:
--    - diabetes_score component based on:
--      * HbA1c trend (50% weight)
--      * FBS control (25% weight)
--      * RBS control (15% weight)
--      * Medication adherence (10% weight)
--
-- 5. **Clinical Decision Support**:
--    - Alert: FBS >200 or <70 → Notify user + emergency contact
--    - Alert: HbA1c ≥9.0 → Flag for urgent doctor consult
--    - Alert: Consistent post-meal spikes → Suggest CGM or more frequent monitoring
--
-- 6. **Meal-Glucose Correlation**:
--    - Link meal_id in random_blood_sugar_logs to meals table
--    - Calculate: meal_glycemic_load → predicted RBS spike
--    - Compare: predicted vs actual RBS
--    - Learn user-specific glycemic response (personalization)
--
-- Integration points:
-- - health_rules: IF HbA1c >7.5 THEN restrict high-GL foods
-- - nutrient_targets: Diabetic users get carb target (135-230g/day)
-- - meal_logging_requirements: Enforce meal logging (need context for RBS)
-- - avatar_health_milestones: Track glucose control improvements
-- - ai_recommendations: Suggest low-GL meals based on recent FBS/RBS
