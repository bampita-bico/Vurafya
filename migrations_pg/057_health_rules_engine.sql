-- Migration 057: Health Rules Engine
-- IF-THEN clinical decision logic linking lab values to dietary recommendations
-- Part of Medical Core Infrastructure (Phase 1)

-- ============================================================================
-- HEALTH RULES TABLE
-- ============================================================================
-- Conditional logic for automated health recommendations
-- Evaluated in application layer against user data

CREATE TABLE health_rules (
    id SERIAL PRIMARY KEY,
    rule_name VARCHAR(100) NOT NULL UNIQUE,
    rule_category VARCHAR(50) NOT NULL,  -- nutrient_recommendation / medication_reminder / lab_alert / meal_restriction / exercise_suggestion

    -- Condition (SQL-like query, evaluated by application)
    condition_sql TEXT NOT NULL,

    -- Action
    recommendation_text TEXT NOT NULL,
    recommendation_type VARCHAR(50) NOT NULL,  -- food_suggestion / medication_check / doctor_consult / emergency / lifestyle_change
    severity VARCHAR(20) NOT NULL,  -- info / warning / critical / emergency

    -- Dietary specifics (JSON arrays of food IDs or nutrient constraints)
    suggested_foods_json TEXT,  -- [6, 20, 21] = Sweet potato, Sukuma wiki, Amaranth
    foods_to_avoid_json TEXT,  -- [12, 45] = Foods to avoid
    nutrient_targets_json TEXT,  -- {"potassium_mg": ">=3000", "sodium_mg": "<2000"}

    -- Rule metadata
    is_active BOOLEAN DEFAULT TRUE,
    priority INTEGER DEFAULT 0,  -- Higher priority rules evaluated first
    applies_to_conditions TEXT,  -- JSON array: ["CKD", "diabetes", "hypertension"]

    -- Audit
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) DEFAULT 'system',

    CHECK (severity IN ('info', 'warning', 'critical', 'emergency'))
);

CREATE INDEX idx_health_rules_category ON health_rules(rule_category, is_active);
CREATE INDEX idx_health_rules_priority ON health_rules(priority DESC, is_active);


-- ============================================================================
-- SEED DATA: POTASSIUM RULES (CKD Critical)
-- ============================================================================

-- Rule 1: Low potassium → Recommend high-K foods
INSERT INTO health_rules VALUES
(1, 'low_potassium_food_suggestion', 'nutrient_recommendation',
    'SELECT 1 FROM potassium_logs WHERE user_id = :user_id AND potassium_value < 3.5 ORDER BY measured_at DESC LIMIT 1',
    'Your recent lab shows low potassium (K+ < 3.5 mEq/L). Consider eating potassium-rich foods like bananas, sweet potatoes, avocados, and leafy greens.',
    'food_suggestion', 'warning',
    '[6, 20, 21, 41, 46, 49, 52]',  -- Sweet potato, Sukuma wiki, Amaranth, Banana, Avocado, Oranges, Tomatoes
    NULL,
    '{"potassium_mg": ">=3000"}',
    TRUE, 10, '["all"]',
    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'system');

-- Rule 2: High potassium (CKD) → Restrict high-K foods
INSERT INTO health_rules VALUES
(2, 'high_potassium_restriction_ckd', 'meal_restriction',
    'SELECT 1 FROM potassium_logs pl JOIN user_profiles up ON pl.user_id = up.user_id WHERE pl.user_id = :user_id AND pl.potassium_value > 5.0 AND up.has_ckd = TRUE ORDER BY pl.measured_at DESC LIMIT 1',
    'Your potassium is elevated (K+ > 5.0 mEq/L) and you have CKD. AVOID high-potassium foods. Limit bananas, oranges, tomatoes, beans, dairy, and salt substitutes.',
    'food_suggestion', 'critical',
    NULL,
    '[6, 20, 21, 41, 46, 49, 52, 15, 16, 17]',  -- Avoid: Sweet potato, greens, banana, avocado, oranges, tomatoes, beans, dairy
    '{"potassium_mg": "<2000"}',
    TRUE, 100, '["CKD"]',
    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'system');

-- Rule 3: Critical hyperkalemia (>6.0) → Emergency
INSERT INTO health_rules VALUES
(3, 'critical_hyperkalemia_emergency', 'lab_alert',
    'SELECT 1 FROM potassium_logs WHERE user_id = :user_id AND potassium_value > 6.0 ORDER BY measured_at DESC LIMIT 1',
    '🚨 CRITICAL: Your potassium is dangerously high (K+ > 6.0 mEq/L). This can cause cardiac arrhythmias. Seek immediate medical attention. DO NOT eat high-potassium foods.',
    'emergency', 'emergency',
    NULL,
    '[6, 20, 21, 41, 46, 49, 52, 15, 16, 17]',
    '{"potassium_mg": "0"}',
    TRUE, 1000, '["all"]',
    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'system');


-- ============================================================================
-- SEED DATA: DIABETES RULES (Blood Glucose Control)
-- ============================================================================

-- Rule 4: High FBS → Low glycemic load breakfast
INSERT INTO health_rules VALUES
(4, 'high_fbs_low_gl_breakfast', 'nutrient_recommendation',
    'SELECT 1 FROM fasting_blood_sugar_logs WHERE user_id = :user_id AND fbs_mg_dl > 130 ORDER BY measured_at DESC LIMIT 1',
    'Your fasting blood sugar is elevated (FBS > 130 mg/dL). Choose a low glycemic load breakfast: oatmeal with nuts, eggs with vegetables, or plain yogurt with berries.',
    'food_suggestion', 'warning',
    '[25, 28, 30, 50, 51]',  -- Oatmeal, Eggs, Yogurt, Berries, Nuts
    '[8, 9, 10]',  -- Avoid: White bread, Rice, Posho (high GL)
    '{"glycemic_load": "<15"}',
    TRUE, 20, '["diabetes", "prediabetes"]',
    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'system');

-- Rule 5: HbA1c worsening → Tighten carb control
INSERT INTO health_rules VALUES
(5, 'hba1c_worsening_carb_restriction', 'meal_restriction',
    'SELECT 1 FROM hba1c_logs WHERE user_id = :user_id AND trend = ''worsening'' ORDER BY measured_at DESC LIMIT 1',
    'Your HbA1c is worsening. Tighten carbohydrate control: Reduce portion sizes of rice, bread, and ugali. Increase vegetables and protein.',
    'food_suggestion', 'critical',
    '[18, 19, 20, 21, 28, 30]',  -- Vegetables, leafy greens, eggs, protein
    '[8, 9, 10, 11]',  -- Avoid: White bread, Rice, Posho, Chapati
    '{"carbohydrates_g": "<150", "fiber_g": ">=30"}',
    TRUE, 90, '["diabetes"]',
    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'system');

-- Rule 6: Critical hyperglycemia (FBS >200) → Emergency
INSERT INTO health_rules VALUES
(6, 'critical_hyperglycemia_emergency', 'lab_alert',
    'SELECT 1 FROM fasting_blood_sugar_logs WHERE user_id = :user_id AND fbs_mg_dl > 200 ORDER BY measured_at DESC LIMIT 1',
    '🚨 CRITICAL: Your fasting blood sugar is dangerously high (FBS > 200 mg/dL). Contact your doctor immediately. Check for ketones if you have Type 1 diabetes.',
    'emergency', 'emergency',
    NULL,
    '[8, 9, 10, 11, 55, 56]',  -- Avoid: All high-carb foods, sugary drinks
    '{"carbohydrates_g": "0"}',
    TRUE, 950, '["diabetes"]',
    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'system');

-- Rule 7: Post-meal glucose spike → Lower glycemic load
INSERT INTO health_rules VALUES
(7, 'post_meal_spike_gl_reduction', 'nutrient_recommendation',
    'SELECT 1 FROM random_blood_sugar_logs WHERE user_id = :user_id AND rbs_mg_dl > 180 AND hours_since_meal BETWEEN 1.5 AND 2.5 ORDER BY measured_at DESC LIMIT 1',
    'Your blood sugar spiked after eating (RBS > 180 mg/dL at 2 hours). That meal had a high glycemic load. Try smaller portions or switch to lower-GL alternatives.',
    'food_suggestion', 'warning',
    '[13, 25, 28]',  -- Brown rice, Oatmeal, Eggs (lower GL)
    '[8, 9]',  -- Avoid: White bread, White rice
    '{"glycemic_load": "<20"}',
    TRUE, 30, '["diabetes", "prediabetes"]',
    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'system');


-- ============================================================================
-- SEED DATA: HYPERTENSION RULES (Blood Pressure Control)
-- ============================================================================

-- Rule 8: High sodium intake + elevated BP → Reduce sodium
INSERT INTO health_rules VALUES
(8, 'high_sodium_bp_elevation', 'nutrient_recommendation',
    'SELECT 1 FROM blood_pressure_trends bpt JOIN daily_nutrition_summary dns ON bpt.user_id = dns.user_id AND DATE(bpt.recorded_at) = dns.date WHERE bpt.user_id = :user_id AND bpt.systolic_mmhg > 140 AND dns.total_sodium_mg > 2000 ORDER BY bpt.recorded_at DESC LIMIT 1',
    'Your blood pressure is elevated (≥140 systolic) and you consumed >2000mg sodium yesterday. Reduce salt intake: Avoid processed foods, canned soups, and salty snacks.',
    'food_suggestion', 'critical',
    '[18, 19, 20, 21, 50]',  -- Fresh vegetables, fruits (naturally low sodium)
    '[60, 61, 62, 63]',  -- Avoid: Processed meats, canned foods, chips, fast food
    '{"sodium_mg": "<1500"}',
    TRUE, 80, '["hypertension"]',
    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'system');

-- Rule 9: Hypertensive crisis (BP >180/120) → Emergency
INSERT INTO health_rules VALUES
(9, 'hypertensive_crisis_emergency', 'lab_alert',
    'SELECT 1 FROM blood_pressure_trends WHERE user_id = :user_id AND (systolic_mmhg > 180 OR diastolic_mmhg > 120) ORDER BY recorded_at DESC LIMIT 1',
    '🚨 CRITICAL: Your blood pressure is dangerously high (≥180/120). This is a hypertensive crisis. Seek emergency medical care immediately.',
    'emergency', 'emergency',
    NULL,
    '[60, 61, 62, 63, 55, 56]',  -- Avoid: All high-sodium foods, caffeine, alcohol
    '{"sodium_mg": "0"}',
    TRUE, 980, '["hypertension", "all"]',
    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'system');

-- Rule 10: Good BP control with low sodium → Reinforce
INSERT INTO health_rules VALUES
(10, 'bp_controlled_reinforce', 'lifestyle_change',
    'SELECT 1 FROM blood_pressure_trends bpt JOIN daily_nutrition_summary dns ON bpt.user_id = dns.user_id AND DATE(bpt.recorded_at) = dns.date WHERE bpt.user_id = :user_id AND bpt.systolic_mmhg < 120 AND bpt.diastolic_mmhg < 80 AND dns.total_sodium_mg < 1500 ORDER BY bpt.recorded_at DESC LIMIT 1',
    '✅ Excellent work! Your blood pressure is well-controlled (<120/80) and you kept sodium under 1500mg. Keep it up!',
    'food_suggestion', 'info',
    '[18, 19, 20, 21, 50]',  -- Continue: Fresh vegetables, fruits
    NULL,
    '{"sodium_mg": "<1500"}',
    TRUE, 5, '["hypertension"]',
    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'system');


-- ============================================================================
-- SEED DATA: CKD RULES (Kidney Function Preservation)
-- ============================================================================

-- Rule 11: eGFR declining → Phosphorus restriction
INSERT INTO health_rules VALUES
(11, 'egfr_declining_phosphorus_restriction', 'meal_restriction',
    'SELECT 1 FROM creatinine_egfr_logs WHERE user_id = :user_id AND egfr_ml_min < 60 AND ckd_stage IN (''Stage 3a'', ''Stage 3b'', ''Stage 4'', ''Stage 5'') ORDER BY measured_at DESC LIMIT 1',
    'Your kidney function is declining (eGFR < 60). You need to restrict phosphorus to prevent bone disease. LIMIT dairy, meat, beans, and processed foods.',
    'food_suggestion', 'critical',
    '[18, 19, 50]',  -- Vegetables, fruits (lower phosphorus)
    '[15, 16, 17, 28, 30]',  -- Avoid: Dairy, meat, beans (high phosphorus)
    '{"phosphorus_mg": "<800"}',
    TRUE, 85, '["CKD"]',
    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'system');

-- Rule 12: CKD Stage 4-5 → Protein restriction
INSERT INTO health_rules VALUES
(12, 'ckd_advanced_protein_restriction', 'meal_restriction',
    'SELECT 1 FROM creatinine_egfr_logs WHERE user_id = :user_id AND ckd_stage IN (''Stage 4'', ''Stage 5'') ORDER BY measured_at DESC LIMIT 1',
    'You have advanced CKD (Stage 4-5). Reduce protein intake to slow kidney decline. Target 0.6-0.8g protein per kg body weight. Consult nephrologist.',
    'doctor_consult', 'critical',
    '[18, 19, 25]',  -- Vegetables, fruits, limited grains
    '[28, 15, 16, 17]',  -- Limit: Eggs, dairy, meat, beans
    '{"protein_g": "formula:0.6-0.8*body_weight_kg"}',
    TRUE, 95, '["CKD"]',
    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'system');


-- ============================================================================
-- SEED DATA: MEDICATION ADHERENCE RULES
-- ============================================================================

-- Rule 13: Missed medications + elevated biomarker → Medication reminder
INSERT INTO health_rules VALUES
(13, 'missed_meds_elevated_biomarker', 'medication_reminder',
    'SELECT 1 FROM adherence_logs al JOIN potassium_logs pl ON al.user_id = pl.user_id WHERE al.user_id = :user_id AND al.status = ''missed'' AND pl.potassium_value > 5.0 AND DATE(al.scheduled_at) = DATE(pl.measured_at) ORDER BY al.scheduled_at DESC LIMIT 1',
    '⚠️ You missed your medication today and your potassium is elevated. Medication adherence is critical for managing your condition. Please take your prescribed dose.',
    'medication_check', 'critical',
    NULL, NULL, NULL,
    TRUE, 70, '["CKD", "diabetes", "hypertension"]',
    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'system');


-- ============================================================================
-- SEED DATA: MEAL LOGGING ENFORCEMENT RULES
-- ============================================================================

-- Rule 14: Large meal gap + diabetes → Warn user
INSERT INTO health_rules VALUES
(14, 'large_meal_gap_diabetes_warning', 'meal_restriction',
    'SELECT 1 FROM meal_logging_compliance WHERE user_id = :user_id AND longest_gap_hours > 8 AND date = CURRENT_DATE',
    '⚠️ You haven''t logged a meal in over 8 hours. For diabetes management, consistent meal timing is important. Please log your meals regularly so we can provide accurate recommendations.',
    'food_suggestion', 'warning',
    NULL, NULL, NULL,
    TRUE, 25, '["diabetes"]',
    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'system');


-- ============================================================================
-- RULE EXECUTION FLOW (Application Layer)
-- ============================================================================
-- 1. User enters lab value (e.g., K+ = 3.2 mEq/L)
-- 2. Application queries health_rules where is_active = TRUE
-- 3. Sort by priority DESC
-- 4. For each rule:
--    a. Execute condition_sql with user_id substitution
--    b. If condition returns result → Rule triggered
--    c. Parse suggested_foods_json / foods_to_avoid_json / nutrient_targets_json
--    d. Generate ai_recommendation entry
--    e. Notify user (in-app, push notification, SMS based on severity)
-- 5. Emergency severity → Bypass notification preferences, force-send alert
--
-- Example execution for Rule 1 (Low Potassium):
-- - Lab value: K+ = 3.2 mEq/L (entered by user)
-- - Condition: K+ < 3.5 → TRUE
-- - Action: Create ai_recommendation with food suggestions [6, 20, 21, 41, 46, 49, 52]
-- - UI displays: "Eat more: Sweet potatoes, Sukuma wiki, Bananas, Avocados"
-- - Meal planner filters: Show high-K recipes
-- - Health score: kidney_score decreases (low K+ is bad)
--
-- Example execution for Rule 2 (High Potassium CKD):
-- - Lab value: K+ = 5.3 mEq/L + user has CKD
-- - Condition: K+ > 5.0 AND has_ckd = TRUE → TRUE
-- - Action: Create ai_recommendation with foods_to_avoid [6, 20, 21, 41, 46, 49, 52]
-- - UI displays: "AVOID: Bananas, sweet potatoes, oranges, beans, dairy"
-- - Meal planner: Hide high-K recipes
-- - Health score: kidney_score decreases (high K+ dangerous for CKD)
