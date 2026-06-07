-- Migration 040: Missing Tables - HIGH PRIORITY
-- Core nutrition, biometrics, and pharmacy tables critical for app functionality
-- Created: 2026-04-12
-- Tables: 27 (Module 1: 5, Module 5: 12, Module 7: 10)

-- ============================================================================
-- MODULE 1: NUTRITION SCIENCE - Critical Missing Tables (5 tables)
-- ============================================================================

-- Glycemic Load Index - Blood sugar impact per food serving
CREATE TABLE IF NOT EXISTS glycemic_load_index (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    food_id INTEGER NOT NULL,
    serving_grams INTEGER NOT NULL,
    glycemic_index INTEGER,  -- Raw GI value (white bread = 100)
    available_carb_g REAL,   -- Net carbs (total - fiber)
    glycemic_load REAL,      -- GL = (GI × available_carb_g) / 100
    gl_category VARCHAR(10), -- low (<10) / medium (10-19) / high (≥20)
    reference_food VARCHAR(60), -- e.g., "white bread" / "glucose"
    data_source VARCHAR(100),
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (food_id) REFERENCES foods(id) ON DELETE CASCADE
);

CREATE INDEX idx_glycemic_load_food ON glycemic_load_index(food_id);
CREATE INDEX idx_glycemic_load_category ON glycemic_load_index(gl_category);

-- Renal Acid Load Data - PRAL values for CKD dietary management
CREATE TABLE IF NOT EXISTS renal_acid_load_data (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    food_id INTEGER NOT NULL,
    pral_value REAL NOT NULL,      -- Potential Renal Acid Load (mEq/100g)
    neap_value REAL,                -- Net Endogenous Acid Production
    acid_category VARCHAR(20),      -- acidic / neutral / alkaline
    phosphorus_mg REAL,             -- Key mineral for CKD
    potassium_mg REAL,              -- Key mineral for CKD
    sodium_mg REAL,                 -- Key mineral for CKD
    protein_g REAL,                 -- Affects acid load
    ckd_recommendation VARCHAR(20), -- avoid / limit / encourage
    serving_size_g INTEGER DEFAULT 100,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (food_id) REFERENCES foods(id) ON DELETE CASCADE
);

CREATE INDEX idx_renal_acid_load_food ON renal_acid_load_data(food_id);
CREATE INDEX idx_renal_acid_load_category ON renal_acid_load_data(acid_category);
CREATE INDEX idx_ckd_recommendation ON renal_acid_load_data(ckd_recommendation);

-- Metabolic Pathways - Biochemical pathways nutrients participate in
CREATE TABLE IF NOT EXISTS metabolic_pathways (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pathway_name VARCHAR(100) NOT NULL UNIQUE, -- Glycolysis, Beta-Oxidation, Citric Acid Cycle
    pathway_type VARCHAR(40),  -- catabolic / anabolic / amphibolic
    description TEXT,
    primary_function TEXT,     -- Energy production / biosynthesis / detoxification
    location VARCHAR(60),      -- mitochondria / cytoplasm / nucleus
    key_enzymes TEXT,          -- JSON array of enzyme names
    cofactors TEXT,            -- JSON array of required vitamins/minerals
    substrates TEXT,           -- JSON array of starting molecules
    products TEXT,             -- JSON array of end products
    energy_yield VARCHAR(40),  -- e.g., "2 ATP + 2 NADH"
    clinical_relevance TEXT,   -- Why this matters for health
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_metabolic_pathway_type ON metabolic_pathways(pathway_type);

-- Nutrient Synergies - Nutrients that enhance each other's absorption
CREATE TABLE IF NOT EXISTS nutrient_synergies (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nutrient_a_id INTEGER NOT NULL,
    nutrient_b_id INTEGER NOT NULL,
    synergy_type VARCHAR(40),      -- absorption / utilization / conversion
    effect_magnitude VARCHAR(20),  -- minor / moderate / significant
    mechanism TEXT,                -- How the synergy works
    example_foods TEXT,            -- Practical food combinations
    clinical_evidence VARCHAR(20), -- weak / moderate / strong
    recommendation TEXT,           -- Practical advice for users
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (nutrient_a_id) REFERENCES nutrients(id) ON DELETE CASCADE,
    FOREIGN KEY (nutrient_b_id) REFERENCES nutrients(id) ON DELETE CASCADE,
    UNIQUE(nutrient_a_id, nutrient_b_id)
);

CREATE INDEX idx_synergy_nutrient_a ON nutrient_synergies(nutrient_a_id);
CREATE INDEX idx_synergy_nutrient_b ON nutrient_synergies(nutrient_b_id);

-- Nutrient Antagonisms - Nutrients that compete or block each other
CREATE TABLE IF NOT EXISTS nutrient_antagonisms (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nutrient_a_id INTEGER NOT NULL,
    nutrient_b_id INTEGER NOT NULL,
    antagonism_type VARCHAR(40),   -- competitive / inhibitory / chelation
    effect_magnitude VARCHAR(20),  -- minor / moderate / significant
    mechanism TEXT,                -- How the antagonism works
    foods_to_separate TEXT,        -- Which foods shouldn't be combined
    time_separation_hours INTEGER, -- Minimum hours between intake
    clinical_evidence VARCHAR(20), -- weak / moderate / strong
    recommendation TEXT,           -- Practical advice for users
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (nutrient_a_id) REFERENCES nutrients(id) ON DELETE CASCADE,
    FOREIGN KEY (nutrient_b_id) REFERENCES nutrients(id) ON DELETE CASCADE,
    UNIQUE(nutrient_a_id, nutrient_b_id)
);

CREATE INDEX idx_antagonism_nutrient_a ON nutrient_antagonisms(nutrient_a_id);
CREATE INDEX idx_antagonism_nutrient_b ON nutrient_antagonisms(nutrient_b_id);

-- ============================================================================
-- MODULE 5: BIOMETRICS & WEARABLES - Critical Missing Tables (12 tables)
-- ============================================================================

-- Body Composition Log - Weight, BMI, body fat percentage tracking
CREATE TABLE IF NOT EXISTS body_composition_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    weight_kg REAL,
    height_cm REAL,
    bmi REAL,                      -- Calculated or measured
    body_fat_pct REAL,
    muscle_mass_kg REAL,
    bone_mass_kg REAL,
    body_water_pct REAL,
    visceral_fat_level INTEGER,    -- 1-59 scale
    metabolic_age INTEGER,         -- Years
    measurement_method VARCHAR(40), -- scale / dexa / bioimpedance / caliper
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_body_comp_user ON body_composition_log(user_id);
CREATE INDEX idx_body_comp_date ON body_composition_log(recorded_at);

-- Sleep Stages Log - Detailed sleep tracking (Vuralis data source)
CREATE TABLE IF NOT EXISTS sleep_stages_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    sleep_date DATE NOT NULL,
    sleep_start TIMESTAMP,
    sleep_end TIMESTAMP,
    total_sleep_minutes INTEGER,
    deep_sleep_minutes INTEGER,
    light_sleep_minutes INTEGER,
    rem_sleep_minutes INTEGER,
    awake_minutes INTEGER,
    sleep_efficiency_pct REAL,     -- (total_sleep / time_in_bed) × 100
    sleep_quality_score REAL,      -- 0.0-1.0 or 0-100
    resting_heart_rate INTEGER,
    hrv_avg REAL,                  -- Heart rate variability
    respiration_rate REAL,
    movement_count INTEGER,
    interruptions INTEGER,
    source VARCHAR(40),            -- fitbit / apple_watch / garmin / manual
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id, sleep_date)
);

CREATE INDEX idx_sleep_user ON sleep_stages_log(user_id);
CREATE INDEX idx_sleep_date ON sleep_stages_log(sleep_date);

-- Mood Logs - Emotional state tracking (Vuralis data source)
CREATE TABLE IF NOT EXISTS mood_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    mood_score INTEGER NOT NULL,   -- 1-10 scale (1=terrible, 10=excellent)
    mood_label VARCHAR(40),        -- happy / sad / anxious / energetic / tired
    energy_level INTEGER,          -- 1-10 scale
    stress_level INTEGER,          -- 1-10 scale
    anxiety_level INTEGER,         -- 1-10 scale
    triggers TEXT,                 -- JSON array: ["work_deadline", "poor_sleep"]
    activities TEXT,               -- JSON array: ["exercise", "meditation"]
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_mood_user ON mood_logs(user_id);
CREATE INDEX idx_mood_date ON mood_logs(recorded_at);

-- Step Count History - Daily activity tracking
CREATE TABLE IF NOT EXISTS step_count_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    recorded_date DATE NOT NULL,
    step_count INTEGER NOT NULL,
    distance_km REAL,
    floors_climbed INTEGER,
    active_minutes INTEGER,
    calories_burned INTEGER,
    source VARCHAR(40),            -- fitbit / apple_watch / garmin / manual
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id, recorded_date, source)
);

CREATE INDEX idx_steps_user ON step_count_history(user_id);
CREATE INDEX idx_steps_date ON step_count_history(recorded_date);

-- Heart Rate Variability - HRV tracking for stress/recovery
CREATE TABLE IF NOT EXISTS heart_rate_variability (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    hrv_ms REAL NOT NULL,          -- Milliseconds (RMSSD standard)
    measurement_type VARCHAR(20),  -- resting / waking / post_exercise
    resting_hr INTEGER,
    recovery_score REAL,           -- 0.0-1.0 or 0-100
    stress_level VARCHAR(20),      -- low / moderate / high
    source VARCHAR(40),
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_hrv_user ON heart_rate_variability(user_id);
CREATE INDEX idx_hrv_date ON heart_rate_variability(recorded_at);

-- Blood Pressure Trends - Aggregated BP analysis
CREATE TABLE IF NOT EXISTS blood_pressure_trends (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    analysis_date DATE NOT NULL,
    period_days INTEGER DEFAULT 30, -- Rolling window
    avg_systolic REAL,
    avg_diastolic REAL,
    max_systolic INTEGER,
    max_diastolic INTEGER,
    min_systolic INTEGER,
    min_diastolic INTEGER,
    measurement_count INTEGER,
    trend VARCHAR(20),             -- improving / stable / worsening
    risk_category VARCHAR(20),     -- normal / elevated / stage1 / stage2
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id, analysis_date)
);

CREATE INDEX idx_bp_trends_user ON blood_pressure_trends(user_id);
CREATE INDEX idx_bp_trends_date ON blood_pressure_trends(analysis_date);

-- Glucose Monitoring - Blood sugar tracking for diabetes management
CREATE TABLE IF NOT EXISTS glucose_monitoring (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    glucose_mg_dl REAL NOT NULL,
    measurement_context VARCHAR(30), -- fasting / before_meal / after_meal / bedtime / random
    meal_id INTEGER,                 -- Link to meals table if post-meal
    hours_since_meal REAL,
    insulin_dose_units REAL,         -- If applicable
    medication_taken BOOLEAN,
    physical_activity TEXT,
    symptoms TEXT,                   -- hypoglycemia / hyperglycemia symptoms
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE SET NULL
);

CREATE INDEX idx_glucose_user ON glucose_monitoring(user_id);
CREATE INDEX idx_glucose_date ON glucose_monitoring(recorded_at);
CREATE INDEX idx_glucose_context ON glucose_monitoring(measurement_context);

-- Menstrual Cycle Log - Cycle tracking for women's health
CREATE TABLE IF NOT EXISTS menstrual_cycle_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    cycle_start_date DATE NOT NULL,
    cycle_end_date DATE,
    cycle_length_days INTEGER,
    period_length_days INTEGER,
    flow_intensity VARCHAR(20),    -- light / moderate / heavy
    symptoms TEXT,                 -- JSON array: ["cramps", "headache", "mood_swings"]
    basal_temp_avg REAL,
    ovulation_date DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_menstrual_user ON menstrual_cycle_log(user_id);
CREATE INDEX idx_menstrual_start ON menstrual_cycle_log(cycle_start_date);

-- Pain Tracking - Chronic pain monitoring
CREATE TABLE IF NOT EXISTS pain_tracking (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    pain_location VARCHAR(60),     -- lower_back / knee / headache / etc
    pain_intensity INTEGER NOT NULL, -- 0-10 scale
    pain_type VARCHAR(40),         -- sharp / dull / burning / throbbing
    duration_minutes INTEGER,
    triggers TEXT,                 -- What caused/worsened it
    relief_methods TEXT,           -- What helped
    medication_taken VARCHAR(100),
    impact_on_activity VARCHAR(20), -- none / mild / moderate / severe
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_pain_user ON pain_tracking(user_id);
CREATE INDEX idx_pain_date ON pain_tracking(recorded_at);
CREATE INDEX idx_pain_location ON pain_tracking(pain_location);

-- Symptom Diary - General symptom tracking
CREATE TABLE IF NOT EXISTS symptom_diary (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    symptom_type VARCHAR(60),      -- nausea / dizziness / fatigue / rash / etc
    severity INTEGER,              -- 1-10 scale
    onset_time TIMESTAMP,
    duration_minutes INTEGER,
    associated_activities TEXT,    -- What was user doing
    potential_triggers TEXT,       -- Food / medication / environment
    relief_methods TEXT,
    seeking_medical_attention BOOLEAN DEFAULT FALSE,
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_symptom_user ON symptom_diary(user_id);
CREATE INDEX idx_symptom_date ON symptom_diary(recorded_at);
CREATE INDEX idx_symptom_type ON symptom_diary(symptom_type);

-- Medication Side Effects - Track adverse reactions
CREATE TABLE IF NOT EXISTS medication_side_effects (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    medication_id INTEGER NOT NULL,
    reported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    side_effect VARCHAR(100) NOT NULL,
    severity VARCHAR(20),          -- mild / moderate / severe / life_threatening
    onset_date DATE,
    resolved BOOLEAN DEFAULT FALSE,
    resolved_date DATE,
    action_taken VARCHAR(40),      -- continued / dose_reduced / discontinued / switched
    reported_to_doctor BOOLEAN DEFAULT FALSE,
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE
);

CREATE INDEX idx_side_effects_user ON medication_side_effects(user_id);
CREATE INDEX idx_side_effects_med ON medication_side_effects(medication_id);
CREATE INDEX idx_side_effects_severity ON medication_side_effects(severity);

-- Vital Signs History - Comprehensive vitals tracking
CREATE TABLE IF NOT EXISTS vital_signs_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    temperature_c REAL,
    pulse_bpm INTEGER,
    respiratory_rate INTEGER,      -- Breaths per minute
    oxygen_saturation_pct INTEGER, -- SpO2
    blood_pressure_systolic INTEGER,
    blood_pressure_diastolic INTEGER,
    measurement_location VARCHAR(40), -- clinic / home / hospital / pharmacy
    measured_by VARCHAR(60),       -- self / nurse / doctor / device
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_vitals_user ON vital_signs_history(user_id);
CREATE INDEX idx_vitals_date ON vital_signs_history(recorded_at);

-- ============================================================================
-- MODULE 7: PHARMACY & MEDICATIONS - Critical Missing Tables (10 tables)
-- ============================================================================

-- Drug Categories - Hierarchical medication classification
CREATE TABLE IF NOT EXISTS drug_categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    parent_id INTEGER,             -- Self-referencing for hierarchy
    category_level INTEGER,        -- 1=top, 2=sub, 3=sub-sub
    description TEXT,
    common_uses TEXT,
    typical_side_effects TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES drug_categories(id) ON DELETE SET NULL
);

CREATE INDEX idx_drug_category_parent ON drug_categories(parent_id);
CREATE INDEX idx_drug_category_level ON drug_categories(category_level);

-- Drug Active Ingredients - Map brand drugs to generic compounds
CREATE TABLE IF NOT EXISTS drug_active_ingredients (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    medication_id INTEGER NOT NULL,
    active_ingredient VARCHAR(200) NOT NULL,
    strength VARCHAR(60),          -- e.g., "500mg", "10mg/ml"
    is_primary BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE
);

CREATE INDEX idx_drug_ingredient_med ON drug_active_ingredients(medication_id);
CREATE INDEX idx_drug_ingredient_name ON drug_active_ingredients(active_ingredient);

-- Pharmacy Order Items - Individual drugs in an order
CREATE TABLE IF NOT EXISTS pharmacy_order_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id INTEGER NOT NULL,
    medication_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price_ugx REAL NOT NULL,
    total_price_ugx REAL NOT NULL,
    dosage_form VARCHAR(40),       -- tablet / capsule / syrup / injection
    strength VARCHAR(60),
    instructions TEXT,             -- Dosage instructions
    substitution_allowed BOOLEAN DEFAULT TRUE,
    actual_medication_dispensed INTEGER, -- If substituted
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES pharmacy_orders(id) ON DELETE CASCADE,
    FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE RESTRICT,
    FOREIGN KEY (actual_medication_dispensed) REFERENCES medications(id) ON DELETE SET NULL
);

CREATE INDEX idx_order_items_order ON pharmacy_order_items(order_id);
CREATE INDEX idx_order_items_med ON pharmacy_order_items(medication_id);

-- Pharmacy Stock Movements - Inventory ledger
CREATE TABLE IF NOT EXISTS pharmacy_stock_movements (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pharmacy_id INTEGER NOT NULL,
    medication_id INTEGER NOT NULL,
    movement_type VARCHAR(20) NOT NULL, -- purchase / sale / return / expiry / write_off / transfer
    quantity INTEGER NOT NULL,          -- Positive for additions, negative for subtractions
    unit_cost_ugx REAL,
    reference_id INTEGER,               -- order_id or purchase_order_id
    batch_number VARCHAR(60),
    expiry_date DATE,
    moved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    moved_by VARCHAR(60),               -- Staff name or system
    notes TEXT,
    FOREIGN KEY (pharmacy_id) REFERENCES pharmacy_locations(id) ON DELETE CASCADE,
    FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE RESTRICT
);

CREATE INDEX idx_stock_movement_pharmacy ON pharmacy_stock_movements(pharmacy_id);
CREATE INDEX idx_stock_movement_med ON pharmacy_stock_movements(medication_id);
CREATE INDEX idx_stock_movement_type ON pharmacy_stock_movements(movement_type);
CREATE INDEX idx_stock_movement_date ON pharmacy_stock_movements(moved_at);

-- Pharmacy Purchase Orders - B2B stock replenishment
CREATE TABLE IF NOT EXISTS pharmacy_purchase_orders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pharmacy_id INTEGER NOT NULL,
    supplier_name VARCHAR(200),
    order_number VARCHAR(60) UNIQUE,
    order_date DATE NOT NULL,
    expected_delivery_date DATE,
    actual_delivery_date DATE,
    total_amount_ugx REAL,
    payment_status VARCHAR(20),    -- pending / partial / paid
    payment_method VARCHAR(40),
    status VARCHAR(20),            -- draft / submitted / confirmed / in_transit / delivered / cancelled
    received_by VARCHAR(60),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (pharmacy_id) REFERENCES pharmacy_locations(id) ON DELETE CASCADE
);

CREATE INDEX idx_purchase_order_pharmacy ON pharmacy_purchase_orders(pharmacy_id);
CREATE INDEX idx_purchase_order_status ON pharmacy_purchase_orders(status);
CREATE INDEX idx_purchase_order_date ON pharmacy_purchase_orders(order_date);

-- Medication Schedules - Complex medication timing
CREATE TABLE IF NOT EXISTS medication_schedules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    medication_id INTEGER NOT NULL,
    prescription_id INTEGER,
    schedule_type VARCHAR(30) NOT NULL, -- fixed_time / interval / with_meal / as_needed
    times_per_day INTEGER,
    scheduled_times TEXT,          -- JSON: ["07:00", "13:00", "19:00"]
    dose_amount VARCHAR(60),       -- "1 tablet", "10ml", "2 capsules"
    meal_relation VARCHAR(20),     -- before / with / after / any
    start_date DATE NOT NULL,
    end_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    reminder_enabled BOOLEAN DEFAULT TRUE,
    reminder_minutes_before INTEGER DEFAULT 15,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE,
    FOREIGN KEY (prescription_id) REFERENCES digital_prescriptions(id) ON DELETE SET NULL
);

CREATE INDEX idx_med_schedule_user ON medication_schedules(user_id);
CREATE INDEX idx_med_schedule_med ON medication_schedules(medication_id);
CREATE INDEX idx_med_schedule_active ON medication_schedules(is_active);

-- Adherence Logs - Patient medication intake confirmation
CREATE TABLE IF NOT EXISTS adherence_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    medication_id INTEGER NOT NULL,
    schedule_id INTEGER,
    scheduled_at TIMESTAMP NOT NULL,
    taken_at TIMESTAMP,
    status VARCHAR(20) NOT NULL,   -- taken / missed / late / skipped
    dose_taken VARCHAR(60),        -- Actual dose taken
    skip_reason VARCHAR(100),      -- If skipped/missed
    side_effects TEXT,             -- Any immediate reactions
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE,
    FOREIGN KEY (schedule_id) REFERENCES medication_schedules(id) ON DELETE SET NULL
);

CREATE INDEX idx_adherence_user ON adherence_logs(user_id);
CREATE INDEX idx_adherence_med ON adherence_logs(medication_id);
CREATE INDEX idx_adherence_status ON adherence_logs(status);
CREATE INDEX idx_adherence_scheduled ON adherence_logs(scheduled_at);

-- Drug Regulatory Status - Country-specific approval
CREATE TABLE IF NOT EXISTS drug_regulatory_status (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    medication_id INTEGER NOT NULL,
    country_code VARCHAR(10) NOT NULL, -- UG / KE / TZ
    regulatory_body VARCHAR(100),  -- NDA Uganda / PPB Kenya / TFDA Tanzania
    status VARCHAR(30) NOT NULL,   -- approved / restricted / controlled / banned / under_review
    registration_number VARCHAR(60),
    approval_date DATE,
    valid_until DATE,
    restrictions TEXT,             -- Special conditions or limitations
    scheduling VARCHAR(20),        -- unscheduled / schedule_2 / schedule_3 / narcotic
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE,
    UNIQUE(medication_id, country_code)
);

CREATE INDEX idx_drug_reg_med ON drug_regulatory_status(medication_id);
CREATE INDEX idx_drug_reg_country ON drug_regulatory_status(country_code);
CREATE INDEX idx_drug_reg_status ON drug_regulatory_status(status);

-- Medication Storage Requirements - Proper storage conditions
CREATE TABLE IF NOT EXISTS medication_storage_reqs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    medication_id INTEGER NOT NULL,
    storage_temp_min_c REAL,
    storage_temp_max_c REAL,
    humidity_controlled BOOLEAN DEFAULT FALSE,
    light_sensitive BOOLEAN DEFAULT FALSE,
    refrigeration_required BOOLEAN DEFAULT FALSE,
    freezing_allowed BOOLEAN DEFAULT FALSE,
    special_container TEXT,        -- amber_bottle / blister_pack / original_packaging
    special_instructions TEXT,     -- "Do not freeze", "Protect from moisture"
    stability_after_opening_days INTEGER, -- Once opened/reconstituted
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE
);

CREATE INDEX idx_med_storage_med ON medication_storage_reqs(medication_id);
CREATE INDEX idx_med_storage_refrigeration ON medication_storage_reqs(refrigeration_required);

-- Batch Expiry Tracking - Pharmacy-level batch management
CREATE TABLE IF NOT EXISTS batch_expiry_tracking (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pharmacy_id INTEGER NOT NULL,
    medication_id INTEGER NOT NULL,
    batch_number VARCHAR(60) NOT NULL,
    quantity_received INTEGER NOT NULL,
    quantity_remaining INTEGER NOT NULL,
    manufacture_date DATE,
    expiry_date DATE NOT NULL,
    days_until_expiry INTEGER,     -- Auto-computed
    alert_threshold_days INTEGER DEFAULT 90,
    status VARCHAR(20),            -- active / expiring_soon / expired / recalled
    supplier VARCHAR(200),
    unit_cost_ugx REAL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (pharmacy_id) REFERENCES pharmacy_locations(id) ON DELETE CASCADE,
    FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE,
    UNIQUE(pharmacy_id, medication_id, batch_number)
);

CREATE INDEX idx_batch_expiry_pharmacy ON batch_expiry_tracking(pharmacy_id);
CREATE INDEX idx_batch_expiry_med ON batch_expiry_tracking(medication_id);
CREATE INDEX idx_batch_expiry_date ON batch_expiry_tracking(expiry_date);
CREATE INDEX idx_batch_expiry_status ON batch_expiry_tracking(status);

-- ============================================================================
-- MIGRATION COMPLETE: 27 HIGH PRIORITY TABLES
-- ============================================================================
