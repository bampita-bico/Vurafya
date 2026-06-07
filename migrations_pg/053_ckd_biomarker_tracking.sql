-- Migration 053: CKD Biomarker Tracking
-- Creates dedicated tables for kidney disease biomarkers with clinical interpretation
-- Part of Medical Core Infrastructure (Phase 1)

-- ============================================================================
-- POTASSIUM TRACKING
-- ============================================================================
-- Critical for CKD management: hyperkalemia is life-threatening
-- Normal range: 3.5-5.0 mEq/L
-- CKD patients need tighter control: 3.5-4.5 mEq/L

CREATE TABLE potassium_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,

    -- Measurement data
    potassium_value DOUBLE PRECISION NOT NULL,
    unit VARCHAR(10) DEFAULT 'mEq/L',  -- mEq/L or mmol/L (equivalent)
    measured_at TIMESTAMP NOT NULL,

    -- Context
    measurement_context VARCHAR(50),  -- routine_lab / urgent / emergency / home_monitor
    lab_facility_id INTEGER,
    notes TEXT,  -- Patient symptoms, medication changes, dietary context

    -- Clinical interpretation (auto-computed or clinician-entered)
    is_critical BOOLEAN DEFAULT FALSE,  -- <2.5 or >6.0 requires immediate intervention
    risk_level VARCHAR(20),  -- normal / borderline_low / low / borderline_high / high / critical

    -- Audit
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    entered_by INTEGER,  -- User self-entered or clinician entered

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (lab_facility_id) REFERENCES partner_facilities(id),
    FOREIGN KEY (entered_by) REFERENCES users(id)
);

CREATE INDEX idx_potassium_logs_user_date ON potassium_logs(user_id, measured_at DESC);
CREATE INDEX idx_potassium_logs_critical ON potassium_logs(is_critical, measured_at DESC);


-- ============================================================================
-- SODIUM TRACKING
-- ============================================================================
-- Critical for blood pressure and fluid balance
-- Normal range: 135-145 mEq/L
-- Hyponatremia (<135) and hypernatremia (>145) both dangerous

CREATE TABLE sodium_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,

    -- Measurement data
    sodium_value DOUBLE PRECISION NOT NULL,
    unit VARCHAR(10) DEFAULT 'mEq/L',
    measured_at TIMESTAMP NOT NULL,

    -- Context
    measurement_context VARCHAR(50),
    lab_facility_id INTEGER,
    notes TEXT,

    -- Clinical interpretation
    is_critical BOOLEAN DEFAULT FALSE,  -- <120 or >160 requires emergency care
    risk_level VARCHAR(20),  -- normal / borderline_low / low / borderline_high / high / critical

    -- Audit
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    entered_by INTEGER,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (lab_facility_id) REFERENCES partner_facilities(id),
    FOREIGN KEY (entered_by) REFERENCES users(id)
);

CREATE INDEX idx_sodium_logs_user_date ON sodium_logs(user_id, measured_at DESC);
CREATE INDEX idx_sodium_logs_critical ON sodium_logs(is_critical, measured_at DESC);


-- ============================================================================
-- CREATININE & eGFR TRACKING
-- ============================================================================
-- Primary measure of kidney function
-- Creatinine normal: 0.6-1.2 mg/dL (varies by age, gender, muscle mass)
-- eGFR normal: ≥90 mL/min/1.73m²
-- CKD staging based on eGFR:
--   Stage 1: ≥90 (kidney damage with normal function)
--   Stage 2: 60-89 (mild decrease)
--   Stage 3a: 45-59 (mild to moderate decrease)
--   Stage 3b: 30-44 (moderate to severe decrease)
--   Stage 4: 15-29 (severe decrease)
--   Stage 5: <15 (kidney failure, dialysis needed)

CREATE TABLE creatinine_egfr_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,

    -- Measurement data
    creatinine_mg_dl DOUBLE PRECISION NOT NULL,
    egfr_ml_min DOUBLE PRECISION,  -- Estimated glomerular filtration rate
    egfr_formula VARCHAR(50),  -- CKD-EPI / MDRD / Cockcroft-Gault / measured_GFR
    measured_at TIMESTAMP NOT NULL,

    -- Clinical staging
    ckd_stage VARCHAR(20),  -- Stage 1 / Stage 2 / Stage 3a / Stage 3b / Stage 4 / Stage 5 / normal

    -- Context
    measurement_context VARCHAR(50),
    lab_facility_id INTEGER,
    notes TEXT,

    -- Additional kidney function markers (optional)
    bun_mg_dl DOUBLE PRECISION,  -- Blood Urea Nitrogen (normal: 7-20 mg/dL)
    urine_albumin_mg DOUBLE PRECISION,  -- Albumin in urine (marker of kidney damage)

    -- Audit
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    entered_by INTEGER,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (lab_facility_id) REFERENCES partner_facilities(id),
    FOREIGN KEY (entered_by) REFERENCES users(id)
);

CREATE INDEX idx_creatinine_egfr_logs_user_date ON creatinine_egfr_logs(user_id, measured_at DESC);
CREATE INDEX idx_creatinine_egfr_logs_ckd_stage ON creatinine_egfr_logs(ckd_stage, measured_at DESC);


-- ============================================================================
-- PHOSPHORUS TRACKING
-- ============================================================================
-- Critical for CKD: high phosphorus damages bones and blood vessels
-- Normal range: 2.5-4.5 mg/dL
-- CKD target: <4.5 mg/dL (tighter control as disease progresses)

CREATE TABLE phosphorus_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,

    -- Measurement data
    phosphorus_mg_dl DOUBLE PRECISION NOT NULL,
    measured_at TIMESTAMP NOT NULL,

    -- Context
    measurement_context VARCHAR(50),
    lab_facility_id INTEGER,
    notes TEXT,

    -- Clinical interpretation
    is_elevated BOOLEAN DEFAULT FALSE,  -- >4.5 mg/dL
    risk_level VARCHAR(20),  -- normal / borderline_high / high / very_high

    -- Related markers (optional)
    calcium_mg_dl DOUBLE PRECISION,  -- Calcium (inverse relationship with phosphorus)
    pth_pg_ml DOUBLE PRECISION,  -- Parathyroid hormone (regulates phosphorus)
    vitamin_d_ng_ml DOUBLE PRECISION,  -- Vitamin D (affects phosphorus absorption)

    -- Audit
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    entered_by INTEGER,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (lab_facility_id) REFERENCES partner_facilities(id),
    FOREIGN KEY (entered_by) REFERENCES users(id)
);

CREATE INDEX idx_phosphorus_logs_user_date ON phosphorus_logs(user_id, measured_at DESC);
CREATE INDEX idx_phosphorus_logs_elevated ON phosphorus_logs(is_elevated, measured_at DESC);


-- ============================================================================
-- CLINICAL NOTES
-- ============================================================================
-- These tables enable the clinical decision engine to:
-- 1. Detect dangerous lab values (e.g., K+ >6.0) → Alert user/doctor
-- 2. Recommend dietary adjustments (e.g., K+ low → High-K foods)
-- 3. Track trends over time (e.g., eGFR declining → Flag progression)
-- 4. Personalize nutrient targets (e.g., CKD Stage 3a → Restrict phosphorus)
-- 5. Calculate health scores (kidney_score component in health_scores table)
--
-- Risk level interpretation is condition-aware:
-- - General population: Standard ranges
-- - CKD patients: Tighter control needed
-- - Diabetes + CKD: Even stricter monitoring
--
-- Integration points:
-- - health_rules table: IF K+ <3.5 THEN recommend high-K foods
-- - nutrient_targets table: CKD Stage 3a → K+ <2000mg/day
-- - ai_recommendations table: Generate personalized meal suggestions
-- - health_scores table: kidney_score calculation
-- - avatar_health_milestones table: Track lab improvements for gamification
