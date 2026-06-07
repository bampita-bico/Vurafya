-- Migration 058: Condition-Specific Nutrient Targets
-- Personalized RDA adjustments based on user's health conditions
-- Part of Medical Core Infrastructure (Phase 1)

-- ============================================================================
-- NUTRIENT TARGETS TABLE (User-Specific)
-- ============================================================================
-- Personalized nutrient goals for each user based on their conditions
-- Overrides generic RDA from nutrients table

CREATE TABLE nutrient_targets (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    nutrient_id INTEGER NOT NULL,

    -- Target range
    target_min DOUBLE PRECISION,  -- Minimum daily intake
    target_max DOUBLE PRECISION,  -- Maximum daily intake
    target_value DOUBLE PRECISION, -- Point target (e.g. for views)
    unit VARCHAR(20) NOT NULL,

    -- Justification
    reason TEXT,  -- "CKD Stage 3a: Restrict potassium to <2g/day to prevent hyperkalemia"
    condition VARCHAR(50),  -- Primary condition driving this target
    condition_stage VARCHAR(20),  -- Stage/severity of condition

    -- Clinical oversight
    is_active BOOLEAN DEFAULT TRUE,
    set_by INTEGER,  -- Medical staff ID who prescribed this target
    set_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,  -- Re-evaluate after condition changes or time passes
    review_frequency_days INTEGER DEFAULT 90,  -- How often to review

    -- Tracking
    last_reviewed_at TIMESTAMP,
    reviewed_by INTEGER,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (nutrient_id) REFERENCES nutrients(id),
    FOREIGN KEY (set_by) REFERENCES medical_staff(id),
    FOREIGN KEY (reviewed_by) REFERENCES medical_staff(id),

    UNIQUE(user_id, nutrient_id, is_active)
);

CREATE INDEX idx_nutrient_targets_user ON nutrient_targets(user_id, is_active);
CREATE INDEX idx_nutrient_targets_condition ON nutrient_targets(condition, condition_stage);


-- ============================================================================
-- CONDITION NUTRIENT TEMPLATES TABLE (Clinical Guidelines)
-- ============================================================================
-- Reference table: Default nutrient targets per condition
-- Used to auto-generate user-specific targets when condition is diagnosed

CREATE TABLE condition_nutrient_templates (
    id SERIAL PRIMARY KEY,
    condition VARCHAR(50) NOT NULL,
    condition_stage VARCHAR(20),  -- NULL = applies to all stages
    nutrient_name VARCHAR(50) NOT NULL,

    -- Default targets
    target_min DOUBLE PRECISION,
    target_max DOUBLE PRECISION,
    target_value DOUBLE PRECISION,
    unit VARCHAR(20) NOT NULL,

    -- Dynamic calculation (for body-weight-dependent targets)
    calculation_formula TEXT,  -- "0.6-0.8 * body_weight_kg" for protein
    formula_variables TEXT,  -- JSON: {"body_weight_kg": "user_profile.weight_kg"}

    -- Clinical context
    clinical_rationale TEXT NOT NULL,
    reference_source VARCHAR(200) NOT NULL,  -- KDOQI 2020, ADA 2024, ACC/AHA 2017
    publication_year INTEGER,

    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(condition, condition_stage, nutrient_name)
);

CREATE INDEX idx_templates_condition ON condition_nutrient_templates(condition, condition_stage);


-- ============================================================================
-- SEED DATA: CKD STAGE 3a TARGETS
-- ============================================================================
-- CKD Stage 3a: eGFR 45-59 mL/min (mild to moderate kidney decline)
-- Key goals: Slow progression, prevent complications

INSERT INTO condition_nutrient_templates VALUES
(1, 'CKD', 'Stage 3a', 'Potassium', 0, 2000, 'mg',
    NULL, NULL,
    'Restrict to <2g/day to prevent hyperkalemia. CKD reduces potassium excretion.',
    'KDOQI 2020 Clinical Practice Guidelines',
    2020, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO condition_nutrient_templates VALUES
(2, 'CKD', 'Stage 3a', 'Phosphorus', 0, 800, 'mg',
    NULL, NULL,
    'Limit phosphorus to <800mg/day to prevent bone disease and vascular calcification.',
    'KDOQI 2020 Clinical Practice Guidelines',
    2020, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO condition_nutrient_templates VALUES
(3, 'CKD', 'Stage 3a', 'Protein', NULL, NULL, 'g',
    '0.6-0.8 * body_weight_kg',
    '{"body_weight_kg": "user_profiles.weight_kg"}',
    'Moderate protein restriction (0.6-0.8g/kg) to slow kidney decline. Too low risks malnutrition.',
    'KDOQI 2020 Clinical Practice Guidelines',
    2020, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO condition_nutrient_templates VALUES
(4, 'CKD', 'Stage 3a', 'Sodium', 0, 2000, 'mg',
    NULL, NULL,
    'Restrict sodium to <2g/day for blood pressure control and fluid management.',
    'KDOQI 2020 Clinical Practice Guidelines',
    2020, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO condition_nutrient_templates VALUES
(5, 'CKD', 'Stage 3a', 'Calcium', 800, 1200, 'mg',
    NULL, NULL,
    'Adequate calcium to prevent bone loss, but avoid excess (increases vascular calcification risk).',
    'KDOQI 2020 Bone Metabolism Guidelines',
    2020, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO condition_nutrient_templates VALUES
(6, 'CKD', 'Stage 3a', 'Fluid', 1500, 2000, 'mL',
    NULL, NULL,
    'Fluid restriction to prevent edema. Adjust based on urine output.',
    'KDOQI 2020 Clinical Practice Guidelines',
    2020, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);


-- ============================================================================
-- SEED DATA: CKD STAGE 3b TARGETS (More Restrictive)
-- ============================================================================
-- CKD Stage 3b: eGFR 30-44 mL/min (moderate to severe)

INSERT INTO condition_nutrient_templates VALUES
(7, 'CKD', 'Stage 3b', 'Potassium', 0, 1500, 'mg',
    NULL, NULL,
    'Tighter potassium control <1.5g/day. Risk of life-threatening hyperkalemia increases.',
    'KDOQI 2020 Clinical Practice Guidelines',
    2020, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO condition_nutrient_templates VALUES
(8, 'CKD', 'Stage 3b', 'Phosphorus', 0, 600, 'mg',
    NULL, NULL,
    'Stricter phosphorus restriction <600mg/day. High risk of bone disease.',
    'KDOQI 2020 Clinical Practice Guidelines',
    2020, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO condition_nutrient_templates VALUES
(9, 'CKD', 'Stage 3b', 'Protein', NULL, NULL, 'g',
    '0.6 * body_weight_kg',
    '{"body_weight_kg": "user_profiles.weight_kg"}',
    'Lower protein target (0.6g/kg) to maximize kidney preservation. Monitor for malnutrition.',
    'KDOQI 2020 Clinical Practice Guidelines',
    2020, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);


-- ============================================================================
-- SEED DATA: CKD STAGE 4-5 TARGETS (Pre-Dialysis)
-- ============================================================================
-- CKD Stage 4-5: eGFR <30 mL/min (severe kidney failure)

INSERT INTO condition_nutrient_templates VALUES
(10, 'CKD', 'Stage 4', 'Potassium', 0, 1200, 'mg',
    NULL, NULL,
    'Very strict potassium control <1.2g/day. Hyperkalemia is life-threatening.',
    'KDOQI 2020 Clinical Practice Guidelines',
    2020, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO condition_nutrient_templates VALUES
(11, 'CKD', 'Stage 5', 'Potassium', 0, 1000, 'mg',
    NULL, NULL,
    'Extreme potassium restriction <1g/day. Patient likely needs dialysis.',
    'KDOQI 2020 Clinical Practice Guidelines',
    2020, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);


-- ============================================================================
-- SEED DATA: DIABETES TYPE 2 TARGETS
-- ============================================================================

INSERT INTO condition_nutrient_templates VALUES
(12, 'Diabetes', 'Type 2', 'Carbohydrates', 135, 230, 'g',
    NULL, NULL,
    'Moderate carb intake (45-60% of calories). Emphasize low-GL sources. Individualize based on glucose control.',
    'ADA 2024 Standards of Medical Care',
    2024, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO condition_nutrient_templates VALUES
(13, 'Diabetes', 'Type 2', 'Fiber', 30, 50, 'g',
    NULL, NULL,
    'High fiber intake (≥30g/day) improves glycemic control and cardiovascular health.',
    'ADA 2024 Standards of Medical Care',
    2024, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO condition_nutrient_templates VALUES
(14, 'Diabetes', 'Type 2', 'Sodium', 0, 2300, 'mg',
    NULL, NULL,
    'Limit sodium to <2300mg/day. Lower target (<1500mg) if hypertensive.',
    'ADA 2024 Standards of Medical Care',
    2024, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO condition_nutrient_templates VALUES
(15, 'Diabetes', 'Type 2', 'Saturated Fat', 0, 20, 'g',
    NULL, NULL,
    'Limit saturated fat to <7% of total calories to reduce cardiovascular risk.',
    'ADA 2024 Standards of Medical Care',
    2024, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO condition_nutrient_templates VALUES
(16, 'Diabetes', 'Type 1', 'Carbohydrates', 130, 300, 'g',
    NULL, NULL,
    'Flexible carb intake for Type 1. Focus on carb counting and insulin adjustment.',
    'ADA 2024 Standards of Medical Care',
    2024, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);


-- ============================================================================
-- SEED DATA: HYPERTENSION TARGETS
-- ============================================================================

INSERT INTO condition_nutrient_templates VALUES
(17, 'Hypertension', NULL, 'Sodium', 0, 1500, 'mg',
    NULL, NULL,
    'Strict sodium restriction to <1500mg/day (ACC/AHA guideline). DASH diet recommended.',
    'ACC/AHA 2017 High Blood Pressure Guidelines',
    2017, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO condition_nutrient_templates VALUES
(18, 'Hypertension', NULL, 'Potassium', 3500, 5000, 'mg',
    NULL, NULL,
    'Increase potassium (3.5-5g/day) to counteract sodium. Helps lower blood pressure naturally.',
    'ACC/AHA 2017 High Blood Pressure Guidelines',
    2017, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO condition_nutrient_templates VALUES
(19, 'Hypertension', NULL, 'Magnesium', 400, 420, 'mg',
    NULL, NULL,
    'Adequate magnesium (400-420mg/day) supports blood pressure regulation.',
    'ACC/AHA 2017 High Blood Pressure Guidelines',
    2017, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);


-- ============================================================================
-- SEED DATA: OBESITY/WEIGHT LOSS TARGETS
-- ============================================================================

INSERT INTO condition_nutrient_templates VALUES
(20, 'Obesity', NULL, 'Calories', NULL, NULL, 'kcal',
    'body_weight_kg * 25 - 500',
    '{"body_weight_kg": "user_profiles.weight_kg"}',
    'Moderate calorie deficit (500 kcal/day) for gradual weight loss (0.5-1kg/week).',
    'WHO Obesity Guidelines 2023',
    2023, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO condition_nutrient_templates VALUES
(21, 'Obesity', NULL, 'Protein', NULL, NULL, 'g',
    '1.2-1.6 * body_weight_kg',
    '{"body_weight_kg": "user_profiles.weight_kg"}',
    'Higher protein (1.2-1.6g/kg) preserves muscle mass during weight loss.',
    'WHO Obesity Guidelines 2023',
    2023, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);


-- ============================================================================
-- SEED DATA: PREGNANCY TARGETS
-- ============================================================================

INSERT INTO condition_nutrient_templates VALUES
(22, 'Pregnancy', 'Trimester 2-3', 'Calories', 300, 450, 'kcal',
    NULL, NULL,
    'Additional 300-450 kcal/day in 2nd-3rd trimester. Quality over quantity.',
    'WHO Antenatal Care Guidelines 2024',
    2024, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO condition_nutrient_templates VALUES
(23, 'Pregnancy', NULL, 'Iron', 27, 45, 'mg',
    NULL, NULL,
    'Increased iron (27mg/day) to support fetal development and prevent anemia.',
    'WHO Antenatal Care Guidelines 2024',
    2024, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO condition_nutrient_templates VALUES
(24, 'Pregnancy', NULL, 'Folate', 600, 800, 'mcg',
    NULL, NULL,
    'High folate (600mcg/day) to prevent neural tube defects. Start before conception.',
    'WHO Antenatal Care Guidelines 2024',
    2024, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);


-- ============================================================================
-- USAGE FLOW (Application Layer)
-- ============================================================================
-- STEP 1: User is diagnosed with condition
-- - Doctor diagnoses: CKD Stage 3a (eGFR = 52)
-- - Application queries condition_nutrient_templates WHERE condition = 'CKD' AND condition_stage = 'Stage 3a'
--
-- STEP 2: Auto-generate user-specific targets
-- - For each template:
--   * If calculation_formula is NULL → Use target_min/target_max directly
--   * If calculation_formula exists → Evaluate formula with user data
--     Example: Protein target = 0.6-0.8 * 70kg = 42-56g/day
--   * INSERT INTO nutrient_targets (user_id, nutrient_id, target_min, target_max, reason, set_by)
--
-- STEP 3: Daily nutrition tracking
-- - User logs meals → daily_nutrition_summary calculates totals
-- - Compare actual intake vs nutrient_targets
-- - Calculate compliance_pct = (actual within range) / total_nutrients * 100
-- - Show user: "✅ Potassium: 1800mg / 2000mg target (90%)"
--
-- STEP 4: Health scoring
-- - nutrient_adherence_score = Average compliance across all active nutrient_targets
-- - Feeds into health_scores.kidney_score / diabetes_score / bp_score
--
-- STEP 5: AI recommendations
-- - IF actual_potassium > target_max THEN trigger health_rule "high_potassium_restriction_ckd"
-- - Generate meal suggestions that fit within all active nutrient_targets
--
-- STEP 6: Review and adjust
-- - Every 90 days (review_frequency_days):
--   * Clinician reviews nutrient_targets
--   * Check if condition has changed (e.g., CKD progressed to Stage 3b)
--   * Update targets accordingly
--   * Set last_reviewed_at = NOW()
