-- Migration 059: Clinical Thresholds & Alerts
-- Defines diagnostic boundaries and triggers automated alerts
-- Final migration of Medical Core Infrastructure (Phase 1)

-- ============================================================================
-- CONDITION THRESHOLDS TABLE
-- ============================================================================
-- Clinical decision points for disease staging and alert triggering
-- Used to classify biomarker values and initiate appropriate responses

CREATE TABLE condition_thresholds (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    condition_name VARCHAR(50) NOT NULL,
    metric_name VARCHAR(50) NOT NULL,  -- potassium / fbs / hba1c / bp_systolic / egfr / creatinine

    -- Threshold definition
    threshold_value REAL NOT NULL,
    comparison_operator VARCHAR(10) NOT NULL,  -- < / > / <= / >= / =

    -- Classification
    severity VARCHAR(20) NOT NULL,  -- normal / borderline / moderate / severe / critical / emergency
    clinical_stage VARCHAR(50),  -- CKD Stage 3a / diabetes_controlled / hypertension_stage2

    -- Response actions
    alert_type VARCHAR(50) NOT NULL,  -- notify_user / notify_doctor / emergency_protocol / no_alert
    alert_message TEXT NOT NULL,
    recommended_action TEXT NOT NULL,

    -- Priority (for multiple matching thresholds, highest priority wins)
    priority INTEGER DEFAULT 0,

    -- Metadata
    reference_source VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CHECK (comparison_operator IN ('<', '>', '<=', '>=', '=')),
    CHECK (severity IN ('normal', 'borderline', 'moderate', 'severe', 'critical', 'emergency')),
    UNIQUE(condition_name, metric_name, threshold_value, comparison_operator)
);

CREATE INDEX idx_thresholds_condition ON condition_thresholds(condition_name, metric_name);
CREATE INDEX idx_thresholds_priority ON condition_thresholds(priority DESC);


-- ============================================================================
-- SEED DATA: CKD STAGING (Based on eGFR)
-- ============================================================================
-- KDOQI CKD Classification based on estimated glomerular filtration rate

-- Normal kidney function
INSERT OR IGNORE INTO condition_thresholds VALUES
(1, 'CKD', 'egfr_ml_min', 90, '>=', 'normal', 'Normal kidney function', 'no_alert',
    'Your kidney function is normal (eGFR ≥90 mL/min/1.73m²).',
    'Maintain healthy lifestyle. Regular check-ups.',
    0, 'KDOQI 2020 CKD Staging', CURRENT_TIMESTAMP);

-- CKD Stage 2 (Mild decline)
INSERT OR IGNORE INTO condition_thresholds VALUES
(2, 'CKD', 'egfr_ml_min', 60, '>=', 'borderline', 'CKD Stage 2', 'notify_user',
    'Your kidney function shows mild decline (eGFR 60-89 mL/min/1.73m²).',
    'Monitor kidney health. Control blood pressure and blood sugar.',
    10, 'KDOQI 2020 CKD Staging', CURRENT_TIMESTAMP);

-- CKD Stage 3a (Mild to moderate decline)
INSERT OR IGNORE INTO condition_thresholds VALUES
(3, 'CKD', 'egfr_ml_min', 45, '>=', 'moderate', 'CKD Stage 3a', 'notify_doctor',
    'Your kidney function shows CKD Stage 3a (eGFR 45-59 mL/min/1.73m²).',
    'Dietary restrictions recommended. Consult nephrologist. Monitor K+, P, protein intake.',
    20, 'KDOQI 2020 CKD Staging', CURRENT_TIMESTAMP);

-- CKD Stage 3b (Moderate to severe decline)
INSERT OR IGNORE INTO condition_thresholds VALUES
(4, 'CKD', 'egfr_ml_min', 30, '>=', 'severe', 'CKD Stage 3b', 'notify_doctor',
    'Your kidney function shows CKD Stage 3b (eGFR 30-44 mL/min/1.73m²).',
    'Stricter dietary restrictions. Specialist care required. Prepare for potential dialysis.',
    30, 'KDOQI 2020 CKD Staging', CURRENT_TIMESTAMP);

-- CKD Stage 4 (Severe decline)
INSERT OR IGNORE INTO condition_thresholds VALUES
(5, 'CKD', 'egfr_ml_min', 15, '>=', 'severe', 'CKD Stage 4', 'notify_doctor',
    '⚠️ Stage 4 CKD (eGFR 15-29 mL/min/1.73m²). Advanced kidney disease.',
    'Prepare for dialysis or transplant discussion. Very strict diet. Specialist care essential.',
    40, 'KDOQI 2020 CKD Staging', CURRENT_TIMESTAMP);

-- CKD Stage 5 (Kidney failure)
INSERT OR IGNORE INTO condition_thresholds VALUES
(6, 'CKD', 'egfr_ml_min', 15, '<', 'critical', 'CKD Stage 5', 'emergency_protocol',
    '🚨 CRITICAL: Stage 5 CKD (eGFR <15 mL/min/1.73m²). Kidney failure.',
    'Dialysis or transplant needed immediately. Contact nephrologist urgently.',
    50, 'KDOQI 2020 CKD Staging', CURRENT_TIMESTAMP);


-- ============================================================================
-- SEED DATA: DIABETES DIAGNOSIS & CONTROL (HbA1c-based)
-- ============================================================================
-- ADA 2024 Diagnostic and Control Criteria

-- Normal (no diabetes)
INSERT OR IGNORE INTO condition_thresholds VALUES
(7, 'Diabetes', 'hba1c_percent', 5.7, '<', 'normal', 'Normal glucose metabolism', 'no_alert',
    'Your HbA1c is normal (<5.7%). No diabetes.',
    'Maintain healthy diet and exercise to prevent diabetes.',
    0, 'ADA 2024 Standards', CURRENT_TIMESTAMP);

-- Prediabetes
INSERT OR IGNORE INTO condition_thresholds VALUES
(8, 'Diabetes', 'hba1c_percent', 5.7, '>=', 'borderline', 'Prediabetes', 'notify_user',
    'Your HbA1c indicates prediabetes (5.7-6.4%). High risk of developing diabetes.',
    'Lifestyle changes critical: Lose 5-7% body weight, exercise 150 min/week, reduce carbs.',
    10, 'ADA 2024 Standards', CURRENT_TIMESTAMP);

-- Diabetes diagnosis
INSERT OR IGNORE INTO condition_thresholds VALUES
(9, 'Diabetes', 'hba1c_percent', 6.5, '>=', 'moderate', 'Diabetes diagnosis', 'notify_doctor',
    'HbA1c ≥6.5% indicates diabetes. Formal diagnosis required (confirm with repeat test).',
    'Start diabetes management plan: Medication, diet, exercise. Consult endocrinologist.',
    20, 'ADA 2024 Standards', CURRENT_TIMESTAMP);

-- Poor control
INSERT OR IGNORE INTO condition_thresholds VALUES
(10, 'Diabetes', 'hba1c_percent', 8.0, '>=', 'severe', 'Diabetes poorly controlled', 'notify_doctor',
    'HbA1c ≥8.0%. Poor diabetes control. High risk of complications.',
    'Urgent medication adjustment needed. Review diet and adherence.',
    30, 'ADA 2024 Standards', CURRENT_TIMESTAMP);

-- Very poor control
INSERT OR IGNORE INTO condition_thresholds VALUES
(11, 'Diabetes', 'hba1c_percent', 9.0, '>=', 'critical', 'Diabetes uncontrolled', 'emergency_protocol',
    '🚨 HbA1c ≥9.0%. Severe uncontrolled diabetes. Immediate intervention required.',
    'Contact doctor immediately. Risk of diabetic ketoacidosis, hyperosmolar state.',
    40, 'ADA 2024 Standards', CURRENT_TIMESTAMP);


-- ============================================================================
-- SEED DATA: FASTING BLOOD SUGAR THRESHOLDS
-- ============================================================================

-- Normal FBS
INSERT OR IGNORE INTO condition_thresholds VALUES
(12, 'Diabetes', 'fbs_mg_dl', 100, '<', 'normal', 'Normal fasting glucose', 'no_alert',
    'Your fasting blood sugar is normal (<100 mg/dL).',
    'Maintain healthy diet and exercise.',
    0, 'ADA 2024 Standards', CURRENT_TIMESTAMP);

-- Prediabetes (IFG - Impaired Fasting Glucose)
INSERT OR IGNORE INTO condition_thresholds VALUES
(13, 'Diabetes', 'fbs_mg_dl', 100, '>=', 'borderline', 'Prediabetes (IFG)', 'notify_user',
    'Your fasting blood sugar is elevated (100-125 mg/dL). Prediabetes (Impaired Fasting Glucose).',
    'Lifestyle modifications to prevent diabetes. Recheck in 3-6 months.',
    10, 'ADA 2024 Standards', CURRENT_TIMESTAMP);

-- Diabetes diagnosis
INSERT OR IGNORE INTO condition_thresholds VALUES
(14, 'Diabetes', 'fbs_mg_dl', 126, '>=', 'moderate', 'Diabetes diagnosis', 'notify_doctor',
    'FBS ≥126 mg/dL indicates diabetes. Confirm with repeat test.',
    'Start diabetes management. Consult doctor for treatment plan.',
    20, 'ADA 2024 Standards', CURRENT_TIMESTAMP);

-- Severe hyperglycemia
INSERT OR IGNORE INTO condition_thresholds VALUES
(15, 'Diabetes', 'fbs_mg_dl', 200, '>=', 'critical', 'Severe hyperglycemia', 'emergency_protocol',
    '🚨 CRITICAL: FBS ≥200 mg/dL. Severe hyperglycemia.',
    'Contact doctor immediately. Risk of diabetic complications. Check for ketones.',
    40, 'ADA 2024 Standards', CURRENT_TIMESTAMP);

-- Hypoglycemia
INSERT OR IGNORE INTO condition_thresholds VALUES
(16, 'Diabetes', 'fbs_mg_dl', 70, '<', 'severe', 'Hypoglycemia', 'emergency_protocol',
    '⚠️ WARNING: FBS <70 mg/dL. Hypoglycemia (low blood sugar).',
    'Consume 15g fast-acting carbs (juice, glucose tablets). Recheck in 15 minutes. If symptomatic, seek help.',
    50, 'ADA 2024 Standards', CURRENT_TIMESTAMP);


-- ============================================================================
-- SEED DATA: HYPERTENSION STAGING (ACC/AHA 2017)
-- ============================================================================

-- Normal BP
INSERT OR IGNORE INTO condition_thresholds VALUES
(17, 'Hypertension', 'bp_systolic', 120, '<', 'normal', 'Normal blood pressure', 'no_alert',
    'Your blood pressure is normal (<120/<80 mmHg).',
    'Maintain healthy lifestyle.',
    0, 'ACC/AHA 2017 Guidelines', CURRENT_TIMESTAMP);

-- Elevated BP
INSERT OR IGNORE INTO condition_thresholds VALUES
(18, 'Hypertension', 'bp_systolic', 120, '>=', 'borderline', 'Elevated blood pressure', 'notify_user',
    'Your blood pressure is elevated (120-129/<80 mmHg).',
    'Lifestyle modifications: Reduce sodium, increase exercise, lose weight if overweight.',
    10, 'ACC/AHA 2017 Guidelines', CURRENT_TIMESTAMP);

-- Hypertension Stage 1
INSERT OR IGNORE INTO condition_thresholds VALUES
(19, 'Hypertension', 'bp_systolic', 130, '>=', 'moderate', 'Hypertension Stage 1', 'notify_doctor',
    'Blood pressure shows Stage 1 Hypertension (130-139/80-89 mmHg).',
    'Lifestyle modifications + medication may be needed. Consult doctor.',
    20, 'ACC/AHA 2017 Guidelines', CURRENT_TIMESTAMP);

-- Hypertension Stage 2
INSERT OR IGNORE INTO condition_thresholds VALUES
(20, 'Hypertension', 'bp_systolic', 140, '>=', 'severe', 'Hypertension Stage 2', 'notify_doctor',
    '⚠️ Stage 2 Hypertension (≥140/≥90 mmHg). Medication required.',
    'Consult doctor for medication. Strict sodium restriction (<1500mg/day).',
    30, 'ACC/AHA 2017 Guidelines', CURRENT_TIMESTAMP);

-- Hypertensive Crisis
INSERT OR IGNORE INTO condition_thresholds VALUES
(21, 'Hypertension', 'bp_systolic', 180, '>=', 'emergency', 'Hypertensive crisis', 'emergency_protocol',
    '🚨 EMERGENCY: Hypertensive crisis (≥180/≥120 mmHg). Immediate medical attention required.',
    'Seek emergency care immediately. Risk of stroke, heart attack, kidney damage.',
    50, 'ACC/AHA 2017 Guidelines', CURRENT_TIMESTAMP);


-- ============================================================================
-- SEED DATA: POTASSIUM THRESHOLDS
-- ============================================================================

-- Hypokalemia (low)
INSERT OR IGNORE INTO condition_thresholds VALUES
(22, 'CKD', 'potassium_meq_l', 3.5, '<', 'moderate', 'Hypokalemia', 'notify_user',
    'Your potassium is low (K+ <3.5 mEq/L). Hypokalemia.',
    'Increase potassium-rich foods: Bananas, sweet potatoes, avocados, oranges.',
    20, 'Clinical Chemistry Standards', CURRENT_TIMESTAMP);

-- Critical hypokalemia
INSERT OR IGNORE INTO condition_thresholds VALUES
(23, 'CKD', 'potassium_meq_l', 2.5, '<', 'critical', 'Severe hypokalemia', 'emergency_protocol',
    '🚨 CRITICAL: K+ <2.5 mEq/L. Severe hypokalemia. Cardiac arrhythmia risk.',
    'Seek immediate medical care. May need IV potassium supplementation.',
    50, 'Clinical Chemistry Standards', CURRENT_TIMESTAMP);

-- Hyperkalemia (high)
INSERT OR IGNORE INTO condition_thresholds VALUES
(24, 'CKD', 'potassium_meq_l', 5.5, '>', 'moderate', 'Hyperkalemia', 'notify_user',
    'Your potassium is elevated (K+ >5.5 mEq/L). Hyperkalemia.',
    'Restrict high-potassium foods. Avoid salt substitutes (contain KCl). Monitor closely.',
    20, 'Clinical Chemistry Standards', CURRENT_TIMESTAMP);

-- Critical hyperkalemia
INSERT OR IGNORE INTO condition_thresholds VALUES
(25, 'CKD', 'potassium_meq_l', 6.0, '>', 'critical', 'Severe hyperkalemia', 'emergency_protocol',
    '🚨 CRITICAL: K+ >6.0 mEq/L. Severe hyperkalemia. Life-threatening cardiac arrhythmia risk.',
    'Seek emergency care immediately. May need dialysis or emergency medications.',
    50, 'Clinical Chemistry Standards', CURRENT_TIMESTAMP);


-- ============================================================================
-- SEED DATA: PHOSPHORUS THRESHOLDS (CKD)
-- ============================================================================

-- Elevated phosphorus
INSERT OR IGNORE INTO condition_thresholds VALUES
(26, 'CKD', 'phosphorus_mg_dl', 4.5, '>', 'moderate', 'Hyperphosphatemia', 'notify_user',
    'Your phosphorus is elevated (P >4.5 mg/dL). Risk of bone disease and vascular calcification.',
    'Restrict phosphorus: Limit dairy, meat, beans, processed foods. Phosphate binders may help.',
    20, 'KDOQI 2020 Guidelines', CURRENT_TIMESTAMP);

-- Severe hyperphosphatemia
INSERT OR IGNORE INTO condition_thresholds VALUES
(27, 'CKD', 'phosphorus_mg_dl', 6.0, '>', 'severe', 'Severe hyperphosphatemia', 'notify_doctor',
    '⚠️ Severe hyperphosphatemia (P >6.0 mg/dL). Urgent intervention needed.',
    'Contact nephrologist. May need phosphate binders or dialysis.',
    30, 'KDOQI 2020 Guidelines', CURRENT_TIMESTAMP);


-- ============================================================================
-- SEED DATA: CREATININE THRESHOLDS
-- ============================================================================

-- Elevated creatinine (males)
INSERT OR IGNORE INTO condition_thresholds VALUES
(28, 'CKD', 'creatinine_mg_dl', 1.2, '>', 'borderline', 'Elevated creatinine (male)', 'notify_user',
    'Your creatinine is elevated (>1.2 mg/dL for males). May indicate kidney dysfunction.',
    'Calculate eGFR for accurate kidney function assessment. Consult doctor.',
    10, 'NIDDK Guidelines', CURRENT_TIMESTAMP);

-- Elevated creatinine (females)
INSERT OR IGNORE INTO condition_thresholds VALUES
(29, 'CKD', 'creatinine_mg_dl_female', 1.1, '>', 'borderline', 'Elevated creatinine (female)', 'notify_user',
    'Your creatinine is elevated (>1.1 mg/dL for females). May indicate kidney dysfunction.',
    'Calculate eGFR for accurate kidney function assessment. Consult doctor.',
    10, 'NIDDK Guidelines', CURRENT_TIMESTAMP);


-- ============================================================================
-- USAGE FLOW (Application Layer)
-- ============================================================================
-- STEP 1: User enters biomarker value
-- - Example: eGFR = 52 mL/min
--
-- STEP 2: Query matching thresholds
-- SELECT * FROM condition_thresholds
-- WHERE metric_name = 'egfr_ml_min'
-- ORDER BY priority DESC
--
-- STEP 3: Evaluate thresholds
-- - Check comparison_operator:
--   * eGFR = 52, threshold 90 >= → FALSE
--   * eGFR = 52, threshold 60 >= → FALSE
--   * eGFR = 52, threshold 45 >= → TRUE ✅ (MATCH: CKD Stage 3a)
--
-- STEP 4: Trigger alert based on alert_type
-- - alert_type = 'notify_doctor':
--   * Create notification for user
--   * Send alert to user's assigned nephrologist
--   * Log in audit_logs
--   * Update user's condition status to "CKD Stage 3a"
--
-- STEP 5: Update nutrient targets
-- - Query condition_nutrient_templates WHERE condition = 'CKD' AND condition_stage = 'Stage 3a'
-- - Auto-generate nutrient_targets for user (K+ <2g, P <800mg, etc.)
--
-- STEP 6: Activate health rules
-- - Enable health_rules where applies_to_conditions includes 'CKD'
-- - Health rules will now trigger dietary recommendations
--
-- Example Emergency Flow:
-- - User enters: K+ = 6.2 mEq/L
-- - Matches threshold: K+ > 6.0, severity = 'critical', alert_type = 'emergency_protocol'
-- - Actions:
--   1. Force-send push notification (bypass user preferences)
--   2. Send SMS alert to user's emergency contact
--   3. Create urgent notification for user's doctor
--   4. Log as critical event in audit_logs
--   5. Flag user account for immediate follow-up
--   6. Display red banner in app: "🚨 CRITICAL: Seek emergency care"
