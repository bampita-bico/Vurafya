-- Migration 056: Clinical Reference Ranges
-- Defines normal and pathological ranges for biomarkers
-- Enables automated risk_level interpretation in lab tracking tables
-- Part of Medical Core Infrastructure (Phase 1)

-- ============================================================================
-- BIOMARKER REFERENCE RANGES TABLE
-- ============================================================================
-- Population-specific and condition-specific reference ranges
-- Supports age/gender/condition-aware interpretation

CREATE TABLE biomarker_reference_ranges (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    biomarker_name VARCHAR(50) NOT NULL,
    unit VARCHAR(20) NOT NULL,

    -- Population filters (NULL = applies to all)
    age_min INTEGER,  -- Minimum age for this range
    age_max INTEGER,  -- Maximum age for this range
    gender VARCHAR(10),  -- male / female / all

    -- Range boundaries (6-level system for granular risk assessment)
    critical_low REAL,  -- Below this = life-threatening emergency
    low_threshold REAL,  -- Below this = abnormally low, needs intervention
    normal_min REAL,  -- Lower bound of normal range
    normal_max REAL,  -- Upper bound of normal range
    high_threshold REAL,  -- Above this = abnormally high, needs intervention
    critical_high REAL,  -- Above this = life-threatening emergency

    -- Condition-specific adjustments
    condition VARCHAR(50),  -- CKD / diabetes / hypertension / pregnancy / all
    condition_stage VARCHAR(20),  -- CKD Stage 3a / diabetes_controlled / NULL

    -- Clinical guidance
    interpretation_notes TEXT,
    action_required TEXT,

    -- Metadata
    reference_source VARCHAR(200),  -- Clinical guideline source
    last_updated DATE DEFAULT CURRENT_DATE,

    UNIQUE(biomarker_name, age_min, age_max, gender, condition, condition_stage)
);

CREATE INDEX idx_biomarker_ranges_name ON biomarker_reference_ranges(biomarker_name);
CREATE INDEX idx_biomarker_ranges_condition ON biomarker_reference_ranges(condition, condition_stage);


-- ============================================================================
-- SEED DATA: POTASSIUM (K+)
-- ============================================================================

-- General population (adults)
INSERT OR IGNORE INTO biomarker_reference_ranges VALUES
(1, 'potassium', 'mEq/L', 18, 120, 'all',
    2.5, 3.5, 3.5, 5.0, 5.5, 6.0,
    'all', NULL,
    'Normal range for adults. Potassium critical for cardiac and muscle function.',
    'Critical if <2.5 (cardiac arrhythmia risk) or >6.0 (hyperkalemia emergency)',
    'WHO/AHA Guidelines', '2026-04-12');

-- CKD patients (tighter control needed)
INSERT OR IGNORE INTO biomarker_reference_ranges VALUES
(2, 'potassium', 'mEq/L', 18, 120, 'all',
    2.0, 3.0, 3.5, 4.5, 5.0, 5.5,
    'CKD', 'Stage 3+',
    'CKD patients need tighter K+ control. Kidneys cannot excrete excess potassium.',
    'Restrict high-K foods if >5.0. Dialysis if >6.5. Avoid salt substitutes (KCl).',
    'KDOQI 2020 Guidelines', '2026-04-12');

-- Elderly (lower upper threshold)
INSERT OR IGNORE INTO biomarker_reference_ranges VALUES
(3, 'potassium', 'mEq/L', 65, 120, 'all',
    2.5, 3.5, 3.5, 4.8, 5.3, 5.8,
    'all', NULL,
    'Elderly adults: Lower threshold due to age-related kidney decline.',
    'Monitor closely if >5.0 in elderly patients.',
    'Geriatric Nephrology Guidelines', '2026-04-12');


-- ============================================================================
-- SEED DATA: SODIUM (Na+)
-- ============================================================================

-- General population
INSERT OR IGNORE INTO biomarker_reference_ranges VALUES
(4, 'sodium', 'mEq/L', 18, 120, 'all',
    120, 130, 135, 145, 150, 160,
    'all', NULL,
    'Normal range for adults. Sodium critical for fluid balance and nerve function.',
    'Critical if <120 (severe hyponatremia, seizure risk) or >160 (severe hypernatremia).',
    'WHO/AHA Guidelines', '2026-04-12');

-- Hypertension patients (target lower range)
INSERT OR IGNORE INTO biomarker_reference_ranges VALUES
(5, 'sodium', 'mEq/L', 18, 120, 'all',
    120, 130, 135, 142, 145, 155,
    'hypertension', NULL,
    'Hypertensive patients: Aim for lower-normal range via dietary sodium restriction.',
    'Dietary sodium <1500mg/day. Avoid processed foods.',
    'ACC/AHA 2017 Guidelines', '2026-04-12');


-- ============================================================================
-- SEED DATA: CREATININE
-- ============================================================================

-- Adult males
INSERT OR IGNORE INTO biomarker_reference_ranges VALUES
(6, 'creatinine', 'mg/dL', 18, 120, 'male',
    0.2, 0.6, 0.7, 1.2, 1.5, 3.0,
    'all', NULL,
    'Normal range for adult males. Creatinine reflects kidney filtration rate.',
    'Elevated creatinine indicates kidney dysfunction. Calculate eGFR for staging.',
    'NIDDK CKD Guidelines', '2026-04-12');

-- Adult females (lower range due to less muscle mass)
INSERT OR IGNORE INTO biomarker_reference_ranges VALUES
(7, 'creatinine', 'mg/dL', 18, 120, 'female',
    0.2, 0.5, 0.6, 1.1, 1.3, 2.5,
    'all', NULL,
    'Normal range for adult females. Lower than males due to muscle mass difference.',
    'Elevated creatinine indicates kidney dysfunction. Calculate eGFR for staging.',
    'NIDDK CKD Guidelines', '2026-04-12');


-- ============================================================================
-- SEED DATA: eGFR (Estimated Glomerular Filtration Rate)
-- ============================================================================

-- General population (adults)
INSERT OR IGNORE INTO biomarker_reference_ranges VALUES
(8, 'egfr', 'mL/min/1.73m²', 18, 120, 'all',
    10, 30, 60, 120, 150, 200,
    'all', NULL,
    'Normal kidney function: ≥90 mL/min. CKD diagnosed if <60 for >3 months.',
    '<15: Kidney failure, dialysis needed. 15-29: Stage 4 CKD. 30-59: Stage 3 CKD.',
    'KDOQI CKD Staging', '2026-04-12');


-- ============================================================================
-- SEED DATA: PHOSPHORUS
-- ============================================================================

-- General population
INSERT OR IGNORE INTO biomarker_reference_ranges VALUES
(9, 'phosphorus', 'mg/dL', 18, 120, 'all',
    1.5, 2.5, 2.5, 4.5, 5.5, 7.0,
    'all', NULL,
    'Normal range for adults. Phosphorus balance critical for bone health.',
    'High phosphorus in CKD causes bone disease and vascular calcification.',
    'NKF-KDOQI Guidelines', '2026-04-12');

-- CKD patients (lower target)
INSERT OR IGNORE INTO biomarker_reference_ranges VALUES
(10, 'phosphorus', 'mg/dL', 18, 120, 'all',
    1.5, 2.5, 2.5, 4.0, 4.5, 6.0,
    'CKD', 'Stage 3+',
    'CKD patients: Target <4.5 mg/dL. Kidneys cannot excrete excess phosphorus.',
    'Restrict high-P foods (dairy, meat, beans). Phosphate binders may be needed.',
    'KDOQI 2020 Guidelines', '2026-04-12');


-- ============================================================================
-- SEED DATA: FASTING BLOOD SUGAR (FBS)
-- ============================================================================

-- General population (diagnostic criteria)
INSERT OR IGNORE INTO biomarker_reference_ranges VALUES
(11, 'fbs', 'mg/dL', 18, 120, 'all',
    40, 70, 70, 100, 125, 250,
    'all', NULL,
    'Normal: <100. Prediabetes: 100-125. Diabetes: ≥126 (on 2+ occasions).',
    '<70: Hypoglycemia. ≥126: Diabetes diagnosis. 200+: Severe hyperglycemia.',
    'ADA 2024 Guidelines', '2026-04-12');

-- Known diabetics (target range)
INSERT OR IGNORE INTO biomarker_reference_ranges VALUES
(12, 'fbs', 'mg/dL', 18, 120, 'all',
    60, 70, 80, 130, 160, 250,
    'diabetes', 'controlled',
    'Target for diabetics: 80-130 mg/dL. Tight control reduces complications.',
    '<70: Hypoglycemia risk. >180: Poor control, adjust medications.',
    'ADA 2024 Standards of Care', '2026-04-12');


-- ============================================================================
-- SEED DATA: RANDOM BLOOD SUGAR (RBS)
-- ============================================================================

-- General population
INSERT OR IGNORE INTO biomarker_reference_ranges VALUES
(13, 'rbs', 'mg/dL', 18, 120, 'all',
    40, 70, 70, 140, 199, 300,
    'all', NULL,
    'Normal post-meal: <140. Prediabetes: 140-199. Diabetes: ≥200.',
    '<70: Hypoglycemia. ≥200: Diabetes diagnosis. Target post-meal <180 for diabetics.',
    'ADA 2024 Guidelines', '2026-04-12');


-- ============================================================================
-- SEED DATA: HbA1c (Glycated Hemoglobin)
-- ============================================================================

-- General population (diagnostic criteria)
INSERT OR IGNORE INTO biomarker_reference_ranges VALUES
(14, 'hba1c', '%', 18, 120, 'all',
    3.0, 4.0, 4.0, 5.6, 6.4, 12.0,
    'all', NULL,
    'Normal: <5.7%. Prediabetes: 5.7-6.4%. Diabetes: ≥6.5%.',
    'Prediabetes 5.7-6.4: Lifestyle modification. ≥6.5: Diabetes diagnosis.',
    'ADA 2024 Guidelines', '2026-04-12');

-- Known diabetics (target range)
INSERT OR IGNORE INTO biomarker_reference_ranges VALUES
(15, 'hba1c', '%', 18, 120, 'all',
    3.5, 5.0, 5.0, 7.0, 8.0, 12.0,
    'diabetes', 'all',
    'Target for diabetics: <7.0% (ADA guideline). <6.5% for tight control (if safe).',
    '≥8.0: Poor control, complications risk. ≥9.0: Urgent intervention needed.',
    'ADA 2024 Standards of Care', '2026-04-12');


-- ============================================================================
-- SEED DATA: BLOOD PRESSURE
-- ============================================================================

-- General population (ACC/AHA 2017 Guidelines)
INSERT OR IGNORE INTO biomarker_reference_ranges VALUES
(16, 'bp_systolic', 'mmHg', 18, 120, 'all',
    70, 90, 90, 120, 139, 180,
    'all', NULL,
    'Normal: <120. Elevated: 120-129. Stage 1 HTN: 130-139. Stage 2: ≥140.',
    '≥180: Hypertensive crisis, emergency care needed. <90: Hypotension.',
    'ACC/AHA 2017 Guidelines', '2026-04-12');

INSERT OR IGNORE INTO biomarker_reference_ranges VALUES
(17, 'bp_diastolic', 'mmHg', 18, 120, 'all',
    40, 60, 60, 80, 89, 120,
    'all', NULL,
    'Normal: <80. Stage 1 HTN: 80-89. Stage 2: ≥90.',
    '≥120: Hypertensive crisis. <60: Hypotension, may cause dizziness.',
    'ACC/AHA 2017 Guidelines', '2026-04-12');


-- ============================================================================
-- SEED DATA: CALCIUM
-- ============================================================================

-- General population
INSERT OR IGNORE INTO biomarker_reference_ranges VALUES
(18, 'calcium', 'mg/dL', 18, 120, 'all',
    6.0, 8.5, 8.5, 10.5, 11.5, 14.0,
    'all', NULL,
    'Normal range for adults. Calcium critical for bones and nerve function.',
    '<8.5: Hypocalcemia. >10.5: Hypercalcemia. Monitor in CKD patients.',
    'Clinical Chemistry Guidelines', '2026-04-12');


-- ============================================================================
-- RISK LEVEL CALCULATION LOGIC
-- ============================================================================
-- Auto-compute risk_level based on these ranges:
--
-- CRITICAL:
--   - value < critical_low OR value > critical_high
--
-- LOW / HIGH:
--   - value < low_threshold → "low"
--   - value > high_threshold → "high"
--
-- BORDERLINE_LOW / BORDERLINE_HIGH:
--   - value < normal_min but ≥ low_threshold → "borderline_low"
--   - value > normal_max but ≤ high_threshold → "borderline_high"
--
-- NORMAL:
--   - value ≥ normal_min AND value ≤ normal_max → "normal"
--
-- Implementation in application layer:
-- 1. When user enters lab value, query this table for matching range
-- 2. Match on: biomarker_name, user's age, user's gender, user's conditions
-- 3. Apply range boundaries to calculate risk_level
-- 4. Store risk_level in respective log table (potassium_logs, fbs_logs, etc.)
-- 5. Trigger health_rules if risk_level = "critical" or "high"
