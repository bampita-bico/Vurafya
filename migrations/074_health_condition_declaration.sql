-- Migration 074: Health Condition Declaration System
-- Users MUST declare health conditions; entire app/game adapts
-- Builds on existing medical_conditions (empty) and user_conditions tables

-- ============================================================================
-- POPULATE MEDICAL_CONDITIONS (existing table, currently empty)
-- ============================================================================

INSERT OR IGNORE INTO medical_conditions (id, condition_name, icd_10_code, category, description, is_chronic, requires_specialist, created_at) VALUES
-- CKD Stages
(1, 'CKD Stage 1', 'N18.1', 'Renal', 'Kidney damage with normal GFR (≥90)', TRUE, TRUE, CURRENT_TIMESTAMP),
(2, 'CKD Stage 2', 'N18.2', 'Renal', 'Mild decrease in GFR (60-89)', TRUE, TRUE, CURRENT_TIMESTAMP),
(3, 'CKD Stage 3a', 'N18.31', 'Renal', 'Moderate decrease in GFR (45-59)', TRUE, TRUE, CURRENT_TIMESTAMP),
(4, 'CKD Stage 3b', 'N18.32', 'Renal', 'Moderate-severe decrease in GFR (30-44)', TRUE, TRUE, CURRENT_TIMESTAMP),
(5, 'CKD Stage 4', 'N18.4', 'Renal', 'Severe decrease in GFR (15-29)', TRUE, TRUE, CURRENT_TIMESTAMP),
(6, 'CKD Stage 5 / ESKD', 'N18.5', 'Renal', 'Kidney failure requiring dialysis or transplant (GFR <15)', TRUE, TRUE, CURRENT_TIMESTAMP),
(7, 'CKD on Hemodialysis', 'Z99.2', 'Renal', 'CKD Stage 5 on hemodialysis', TRUE, TRUE, CURRENT_TIMESTAMP),
(8, 'CKD on Peritoneal Dialysis', 'Z99.2', 'Renal', 'CKD Stage 5 on peritoneal dialysis', TRUE, TRUE, CURRENT_TIMESTAMP),
(9, 'Kidney Transplant Recipient', 'Z94.0', 'Renal', 'Post kidney transplant', TRUE, TRUE, CURRENT_TIMESTAMP),

-- Diabetes
(10, 'Diabetes Type 1', 'E10', 'Endocrine', 'Insulin-dependent diabetes mellitus', TRUE, TRUE, CURRENT_TIMESTAMP),
(11, 'Diabetes Type 2', 'E11', 'Endocrine', 'Non-insulin-dependent diabetes mellitus', TRUE, FALSE, CURRENT_TIMESTAMP),
(12, 'Gestational Diabetes', 'O24.4', 'Endocrine', 'Diabetes first recognized during pregnancy', FALSE, TRUE, CURRENT_TIMESTAMP),
(13, 'Pre-Diabetes', 'R73.03', 'Endocrine', 'Impaired glucose tolerance / impaired fasting glucose', FALSE, FALSE, CURRENT_TIMESTAMP),

-- Cardiovascular
(14, 'Hypertension Stage 1', 'I10', 'Cardiovascular', 'Blood pressure 130-139/80-89 mmHg', TRUE, FALSE, CURRENT_TIMESTAMP),
(15, 'Hypertension Stage 2', 'I10', 'Cardiovascular', 'Blood pressure ≥140/90 mmHg', TRUE, FALSE, CURRENT_TIMESTAMP),
(16, 'Heart Failure', 'I50.9', 'Cardiovascular', 'Chronic heart failure', TRUE, TRUE, CURRENT_TIMESTAMP),
(17, 'Coronary Artery Disease', 'I25.10', 'Cardiovascular', 'Atherosclerotic heart disease', TRUE, TRUE, CURRENT_TIMESTAMP),

-- Metabolic
(18, 'Gout', 'M10.9', 'Metabolic', 'Crystal arthropathy from uric acid buildup', TRUE, FALSE, CURRENT_TIMESTAMP),
(19, 'Obesity (BMI ≥30)', 'E66.9', 'Metabolic', 'Body mass index 30 or greater', TRUE, FALSE, CURRENT_TIMESTAMP),
(20, 'Dyslipidemia', 'E78.5', 'Metabolic', 'Abnormal cholesterol/triglyceride levels', TRUE, FALSE, CURRENT_TIMESTAMP),

-- Other Chronic
(21, 'HIV/AIDS', 'B20', 'Infectious', 'Human immunodeficiency virus infection', TRUE, TRUE, CURRENT_TIMESTAMP),
(22, 'Sickle Cell Disease', 'D57.1', 'Hematological', 'Sickle cell anemia', TRUE, TRUE, CURRENT_TIMESTAMP),
(23, 'Asthma', 'J45.9', 'Respiratory', 'Chronic inflammatory airway disease', TRUE, FALSE, CURRENT_TIMESTAMP),
(24, 'Epilepsy', 'G40.9', 'Neurological', 'Recurrent seizure disorder', TRUE, TRUE, CURRENT_TIMESTAMP),
(25, 'Liver Disease / Cirrhosis', 'K74.60', 'Hepatic', 'Chronic liver disease', TRUE, TRUE, CURRENT_TIMESTAMP),

-- Women's Health
(26, 'Pregnancy', 'Z33.1', 'Maternal', 'Normal pregnancy requiring nutritional monitoring', FALSE, TRUE, CURRENT_TIMESTAMP),
(27, 'Polycystic Ovary Syndrome', 'E28.2', 'Endocrine', 'PCOS with metabolic implications', TRUE, TRUE, CURRENT_TIMESTAMP),

-- General / Wellness
(28, 'Malaria-Prone (Prophylaxis)', 'Z23.8', 'Infectious', 'Living in malaria-endemic region', FALSE, FALSE, CURRENT_TIMESTAMP),
(29, 'Anemia (Iron Deficiency)', 'D50.9', 'Hematological', 'Iron deficiency anemia', FALSE, FALSE, CURRENT_TIMESTAMP),
(30, 'Healthy / No Condition', NULL, 'Wellness', 'No diagnosed medical condition - general health optimization', FALSE, FALSE, CURRENT_TIMESTAMP);

-- ============================================================================
-- USER HEALTH DECLARATIONS (extends existing user_conditions)
-- Add columns the existing table lacks
-- ============================================================================

ALTER TABLE user_conditions ADD COLUMN stage VARCHAR(20);
ALTER TABLE user_conditions ADD COLUMN is_primary BOOLEAN DEFAULT FALSE;
ALTER TABLE user_conditions ADD COLUMN verified_by_doctor BOOLEAN DEFAULT FALSE;
ALTER TABLE user_conditions ADD COLUMN declaration_source VARCHAR(20) DEFAULT 'self_report';
    -- self_report, doctor_verified, lab_confirmed
ALTER TABLE user_conditions ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Add declaration flag to users table
ALTER TABLE users ADD COLUMN has_completed_health_declaration BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN health_declaration_date TIMESTAMP;
ALTER TABLE users ADD COLUMN primary_condition_id INTEGER;

-- ============================================================================
-- CONDITION GAME MODIFIERS
-- How each condition changes game mechanics
-- ============================================================================

CREATE TABLE IF NOT EXISTS condition_game_modifiers (
    id INTEGER PRIMARY KEY,
    condition_id INTEGER NOT NULL REFERENCES medical_conditions(id),
    modifier_type VARCHAR(40) NOT NULL,
        -- xp_multiplier, boss_unlock, quest_unlock, region_unlock,
        -- activity_restriction, bonus_xp_action, pet_behavior
    modifier_key VARCHAR(80) NOT NULL,
    modifier_value REAL,
    modifier_text TEXT,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- CONDITION NUTRITION RULES
-- Per-condition dietary rules (supplements condition_nutrient_templates)
-- ============================================================================

CREATE TABLE IF NOT EXISTS condition_nutrition_rules (
    id INTEGER PRIMARY KEY,
    condition_id INTEGER NOT NULL REFERENCES medical_conditions(id),
    rule_type VARCHAR(40) NOT NULL,
        -- nutrient_limit, food_encourage, food_restrict, pral_target, gi_target
    nutrient_or_food VARCHAR(60),
    min_value REAL,
    max_value REAL,
    unit VARCHAR(20),
    priority VARCHAR(20) DEFAULT 'recommended',
        -- critical, recommended, optional
    clinical_rationale TEXT,
    reference_source VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- CONDITION ONBOARDING FLOW
-- Questions asked during health declaration
-- ============================================================================

CREATE TABLE IF NOT EXISTS condition_onboarding_flow (
    id INTEGER PRIMARY KEY,
    condition_id INTEGER REFERENCES medical_conditions(id),
        -- NULL = asked for all conditions
    question_text TEXT NOT NULL,
    question_type VARCHAR(20) NOT NULL,
        -- single_choice, multi_choice, number, date, text
    options TEXT,
        -- JSON array for choice questions
    is_required BOOLEAN DEFAULT TRUE,
    sequence_order INTEGER NOT NULL,
    maps_to_field VARCHAR(60),
        -- which user_conditions or user profile field this populates
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- SEED: CONDITION GAME MODIFIERS (~60 entries)
-- ============================================================================

INSERT OR IGNORE INTO condition_game_modifiers (condition_id, modifier_type, modifier_key, modifier_value, modifier_text, description) VALUES
-- CKD modifiers (applies to conditions 1-9)
(1, 'xp_multiplier', 'kidney_safe_meal', 1.1, NULL, 'CKD Stage 1: 10% bonus XP for kidney-safe meals'),
(3, 'xp_multiplier', 'kidney_safe_meal', 1.25, NULL, 'CKD Stage 3a: 25% bonus XP for kidney-safe meals'),
(5, 'xp_multiplier', 'kidney_safe_meal', 1.5, NULL, 'CKD Stage 4: 50% bonus XP for kidney-safe meals'),
(6, 'xp_multiplier', 'kidney_safe_meal', 2.0, NULL, 'CKD Stage 5/ESKD: 2x XP for kidney-safe meals'),
(7, 'xp_multiplier', 'dialysis_compliance', 2.0, NULL, 'Hemodialysis: 2x XP for dialysis-day compliance'),
(8, 'xp_multiplier', 'dialysis_compliance', 2.0, NULL, 'Peritoneal dialysis: 2x XP for daily exchange compliance'),
(3, 'boss_unlock', 'phosphorus_phantom', 1.0, NULL, 'CKD Stage 3a: Unlock Phosphorus Phantom boss'),
(4, 'boss_unlock', 'phosphorus_phantom', 1.0, NULL, 'CKD Stage 3b: Unlock Phosphorus Phantom boss'),
(5, 'boss_unlock', 'potassium_kraken', 1.0, NULL, 'CKD Stage 4: Unlock Potassium Kraken boss'),
(6, 'boss_unlock', 'uremia_dragon', 1.0, NULL, 'CKD Stage 5: Unlock Uremia Dragon boss'),
(7, 'boss_unlock', 'fluid_overload_titan', 1.0, NULL, 'Hemodialysis: Unlock Fluid Overload Titan boss'),
(3, 'region_unlock', 'renal_reef_early', 1.0, NULL, 'CKD patients unlock Renal Reef at level 8 instead of 15'),
(4, 'region_unlock', 'renal_reef_early', 1.0, NULL, 'CKD patients unlock Renal Reef at level 8 instead of 15'),
(5, 'region_unlock', 'renal_reef_early', 1.0, NULL, 'CKD patients unlock Renal Reef at level 8 instead of 15'),
(6, 'region_unlock', 'renal_reef_early', 1.0, NULL, 'CKD patients unlock Renal Reef at level 8 instead of 15'),
(1, 'quest_unlock', 'ckd_quests', 1.0, NULL, 'CKD: Unlock all CKD-focused quests'),
(2, 'quest_unlock', 'ckd_quests', 1.0, NULL, 'CKD: Unlock all CKD-focused quests'),
(3, 'quest_unlock', 'ckd_quests', 1.0, NULL, 'CKD: Unlock all CKD-focused quests'),
(4, 'quest_unlock', 'ckd_quests', 1.0, NULL, 'CKD: Unlock all CKD-focused quests'),
(5, 'quest_unlock', 'ckd_quests', 1.0, NULL, 'CKD: Unlock all CKD-focused quests'),
(6, 'quest_unlock', 'ckd_quests', 1.0, NULL, 'CKD: Unlock all CKD-focused quests'),

-- Diabetes modifiers
(10, 'xp_multiplier', 'glucose_in_range', 1.3, NULL, 'Type 1: 30% bonus XP for glucose in range'),
(11, 'xp_multiplier', 'glucose_in_range', 1.2, NULL, 'Type 2: 20% bonus XP for glucose in range'),
(10, 'boss_unlock', 'sugar_dragon', 1.0, NULL, 'Type 1 Diabetes: Unlock Sugar Dragon boss'),
(11, 'boss_unlock', 'sugar_dragon', 1.0, NULL, 'Type 2 Diabetes: Unlock Sugar Dragon boss'),
(13, 'boss_unlock', 'sugar_dragon', 1.0, NULL, 'Pre-Diabetes: Unlock Sugar Dragon boss'),
(10, 'region_unlock', 'endocrine_empire_early', 1.0, NULL, 'Diabetes patients unlock Endocrine Empire at level 12 instead of 20'),
(11, 'region_unlock', 'endocrine_empire_early', 1.0, NULL, 'Diabetes patients unlock Endocrine Empire at level 12 instead of 20'),
(10, 'quest_unlock', 'diabetes_quests', 1.0, NULL, 'Diabetes: Unlock all diabetes-focused quests'),
(11, 'quest_unlock', 'diabetes_quests', 1.0, NULL, 'Diabetes: Unlock all diabetes-focused quests'),
(12, 'quest_unlock', 'diabetes_quests', 1.0, NULL, 'Gestational Diabetes: Unlock diabetes quests'),

-- Hypertension modifiers
(14, 'xp_multiplier', 'bp_in_range', 1.15, NULL, 'Stage 1 HTN: 15% bonus XP for BP in range'),
(15, 'xp_multiplier', 'bp_in_range', 1.25, NULL, 'Stage 2 HTN: 25% bonus XP for BP in range'),
(14, 'boss_unlock', 'bp_storm_giant', 1.0, NULL, 'Hypertension: Unlock BP Storm Giant boss'),
(15, 'boss_unlock', 'bp_storm_giant', 1.0, NULL, 'Hypertension: Unlock BP Storm Giant boss'),
(14, 'boss_unlock', 'salt_golem', 1.0, NULL, 'Hypertension: Unlock Salt Golem boss'),
(15, 'boss_unlock', 'salt_golem', 1.0, NULL, 'Hypertension: Unlock Salt Golem boss'),
(14, 'quest_unlock', 'hypertension_quests', 1.0, NULL, 'HTN: Unlock hypertension quests'),
(15, 'quest_unlock', 'hypertension_quests', 1.0, NULL, 'HTN: Unlock hypertension quests'),

-- Heart Failure / CAD
(16, 'xp_multiplier', 'sodium_control', 1.3, NULL, 'Heart Failure: 30% bonus XP for sodium control'),
(17, 'xp_multiplier', 'cholesterol_control', 1.2, NULL, 'CAD: 20% bonus XP for cholesterol management'),
(16, 'boss_unlock', 'fluid_overload_titan', 1.0, NULL, 'Heart Failure: Unlock Fluid Overload Titan boss'),
(17, 'boss_unlock', 'cholesterol_hydra', 1.0, NULL, 'CAD: Unlock Cholesterol Hydra boss'),

-- Gout
(18, 'xp_multiplier', 'low_purine_meal', 1.2, NULL, 'Gout: 20% bonus XP for low-purine meals'),
(18, 'boss_unlock', 'uric_acid_titan', 1.0, NULL, 'Gout: Unlock Uric Acid Titan boss'),

-- Obesity
(19, 'xp_multiplier', 'calorie_target_hit', 1.2, NULL, 'Obesity: 20% bonus XP for hitting calorie target'),
(19, 'boss_unlock', 'calorie_overlord', 1.0, NULL, 'Obesity: Unlock Calorie Overlord boss'),
(19, 'boss_unlock', 'sedentary_shadow', 1.0, NULL, 'Obesity: Unlock Sedentary Shadow boss'),

-- HIV/AIDS
(21, 'xp_multiplier', 'arv_adherence', 1.5, NULL, 'HIV: 50% bonus XP for ARV medication adherence'),
(21, 'bonus_xp_action', 'nutrition_logging', 1.3, NULL, 'HIV: 30% bonus for nutrition logging (nutrition critical)'),

-- Sickle Cell
(22, 'xp_multiplier', 'hydration_goal', 1.3, NULL, 'Sickle Cell: 30% bonus XP for hydration goals'),
(22, 'boss_unlock', 'dehydration_wraith', 1.0, NULL, 'Sickle Cell: Unlock Dehydration Wraith boss'),

-- Pregnancy
(26, 'xp_multiplier', 'prenatal_nutrition', 1.3, NULL, 'Pregnancy: 30% bonus XP for prenatal nutrition compliance'),
(26, 'activity_restriction', 'high_intensity_challenges', 0.0, NULL, 'Pregnancy: Restrict high-intensity physical challenges'),

-- Anemia
(29, 'xp_multiplier', 'iron_rich_meal', 1.2, NULL, 'Anemia: 20% bonus XP for iron-rich meals'),
(29, 'boss_unlock', 'iron_deficiency_specter', 1.0, NULL, 'Anemia: Unlock Iron Deficiency Specter boss'),

-- Healthy / No Condition
(30, 'xp_multiplier', 'general_wellness', 1.0, NULL, 'Healthy: Standard XP rates (no bonus/penalty)'),
(30, 'quest_unlock', 'general_quests', 1.0, NULL, 'Healthy: Access all general wellness quests');

-- ============================================================================
-- SEED: CONDITION NUTRITION RULES (~80 entries)
-- ============================================================================

INSERT OR IGNORE INTO condition_nutrition_rules (condition_id, rule_type, nutrient_or_food, min_value, max_value, unit, priority, clinical_rationale, reference_source) VALUES
-- CKD Stage 3a (condition 3)
(3, 'nutrient_limit', 'Potassium', NULL, 2000, 'mg/day', 'critical', 'Restrict K+ to prevent hyperkalemia', 'KDOQI 2020'),
(3, 'nutrient_limit', 'Phosphorus', NULL, 800, 'mg/day', 'critical', 'Limit P to prevent bone disease', 'KDOQI 2020'),
(3, 'nutrient_limit', 'Sodium', NULL, 2000, 'mg/day', 'critical', 'Restrict Na for BP control', 'KDOQI 2020'),
(3, 'nutrient_limit', 'Protein', NULL, NULL, 'g/kg/day', 'critical', '0.6-0.8g/kg to slow progression', 'KDOQI 2020'),
(3, 'pral_target', 'PRAL', NULL, 0, 'mEq/day', 'recommended', 'Target alkalizing diet to slow progression', 'KDOQI 2020'),
(3, 'food_encourage', 'Alkalizing foods', NULL, NULL, NULL, 'recommended', 'PRAL-negative foods slow CKD progression', 'Goraya 2012'),
(3, 'food_restrict', 'Processed meats', NULL, NULL, NULL, 'critical', 'High P additives + high Na', 'KDOQI 2020'),

-- CKD Stage 4 (condition 5)
(5, 'nutrient_limit', 'Potassium', NULL, 1500, 'mg/day', 'critical', 'Stricter K+ as GFR declines', 'KDOQI 2020'),
(5, 'nutrient_limit', 'Phosphorus', NULL, 700, 'mg/day', 'critical', 'Tighter P control', 'KDOQI 2020'),
(5, 'nutrient_limit', 'Sodium', NULL, 1500, 'mg/day', 'critical', 'Strict Na for fluid/BP control', 'KDOQI 2020'),
(5, 'nutrient_limit', 'Protein', NULL, NULL, 'g/kg/day', 'critical', '0.6g/kg strict restriction', 'KDOQI 2020'),
(5, 'nutrient_limit', 'Fluid', NULL, 1500, 'ml/day', 'critical', 'Fluid restriction if edema', 'KDOQI 2020'),

-- CKD Stage 5 / Dialysis (conditions 6, 7, 8)
(6, 'nutrient_limit', 'Potassium', NULL, 2000, 'mg/day', 'critical', 'K+ restriction on dialysis', 'KDOQI 2020'),
(6, 'nutrient_limit', 'Phosphorus', NULL, 800, 'mg/day', 'critical', 'P restriction with binders', 'KDOQI 2020'),
(6, 'nutrient_limit', 'Protein', 72, NULL, 'g/day', 'critical', '1.0-1.2g/kg on dialysis (increased need)', 'KDOQI 2020'),
(7, 'nutrient_limit', 'Potassium', NULL, 2000, 'mg/day', 'critical', 'K+ fluctuates rapidly on HD', 'KDOQI 2020'),
(7, 'nutrient_limit', 'Fluid', NULL, 1000, 'ml/day', 'critical', 'Strict fluid control between HD sessions', 'KDOQI 2020'),
(7, 'nutrient_limit', 'Phosphorus', NULL, 800, 'mg/day', 'critical', 'P restriction on hemodialysis', 'KDOQI 2020'),
(8, 'nutrient_limit', 'Protein', 72, NULL, 'g/day', 'critical', 'Higher protein need on PD (peritoneal losses)', 'KDOQI 2020'),

-- Diabetes Type 1 (condition 10)
(10, 'gi_target', 'Glycemic Index', NULL, 55, 'GI', 'recommended', 'Prefer low-GI foods for stable glucose', 'ADA 2024'),
(10, 'nutrient_limit', 'Added Sugar', NULL, 25, 'g/day', 'critical', 'Minimize added sugars', 'ADA 2024'),
(10, 'nutrient_limit', 'Carbohydrates', NULL, NULL, 'g/meal', 'recommended', 'Count carbs for insulin dosing', 'ADA 2024'),
(10, 'food_encourage', 'Fiber-rich foods', 25, NULL, 'g/day', 'recommended', 'Fiber improves glycemic control', 'ADA 2024'),

-- Diabetes Type 2 (condition 11)
(11, 'gi_target', 'Glycemic Index', NULL, 55, 'GI', 'recommended', 'Low-GI diet for Type 2', 'ADA 2024'),
(11, 'nutrient_limit', 'Added Sugar', NULL, 25, 'g/day', 'critical', 'Restrict added sugars', 'ADA 2024'),
(11, 'nutrient_limit', 'Calories', NULL, NULL, 'kcal/day', 'recommended', 'Calorie control for weight management', 'ADA 2024'),
(11, 'food_encourage', 'Fiber-rich foods', 30, NULL, 'g/day', 'recommended', 'High fiber improves insulin sensitivity', 'ADA 2024'),
(11, 'food_restrict', 'Sugary beverages', NULL, NULL, NULL, 'critical', 'Eliminate sugar-sweetened drinks', 'ADA 2024'),

-- Pre-Diabetes (condition 13)
(13, 'nutrient_limit', 'Added Sugar', NULL, 25, 'g/day', 'recommended', 'Reduce sugar to prevent progression', 'ADA 2024'),
(13, 'food_encourage', 'Whole grains', NULL, NULL, NULL, 'recommended', 'Replace refined with whole grains', 'ADA 2024'),

-- Hypertension Stage 1 (condition 14)
(14, 'nutrient_limit', 'Sodium', NULL, 2300, 'mg/day', 'critical', 'DASH diet sodium limit', 'AHA 2023'),
(14, 'nutrient_limit', 'Potassium', 3500, 4700, 'mg/day', 'recommended', 'Increase K+ for BP reduction (opposite of CKD!)', 'AHA 2023'),
(14, 'food_encourage', 'DASH diet foods', NULL, NULL, NULL, 'recommended', 'Fruits, vegetables, low-fat dairy, whole grains', 'AHA 2023'),
(14, 'food_restrict', 'Processed foods', NULL, NULL, NULL, 'recommended', 'High sodium processed foods', 'AHA 2023'),

-- Hypertension Stage 2 (condition 15)
(15, 'nutrient_limit', 'Sodium', NULL, 1500, 'mg/day', 'critical', 'Strict sodium for Stage 2 HTN', 'AHA 2023'),
(15, 'nutrient_limit', 'Alcohol', NULL, 1, 'drinks/day', 'recommended', 'Limit alcohol for BP control', 'AHA 2023'),
(15, 'food_encourage', 'DASH diet foods', NULL, NULL, NULL, 'critical', 'Strict DASH diet adherence', 'AHA 2023'),

-- Heart Failure (condition 16)
(16, 'nutrient_limit', 'Sodium', NULL, 1500, 'mg/day', 'critical', 'Strict Na restriction for fluid management', 'ACC/AHA 2022'),
(16, 'nutrient_limit', 'Fluid', NULL, 1500, 'ml/day', 'critical', 'Fluid restriction if symptomatic', 'ACC/AHA 2022'),

-- Gout (condition 18)
(18, 'nutrient_limit', 'Purines', NULL, NULL, NULL, 'critical', 'Avoid high-purine foods (organ meats, shellfish)', 'ACR 2020'),
(18, 'food_restrict', 'Organ meats', NULL, NULL, NULL, 'critical', 'Very high purine content', 'ACR 2020'),
(18, 'food_restrict', 'Alcohol (beer/spirits)', NULL, NULL, NULL, 'critical', 'Beer especially increases uric acid', 'ACR 2020'),
(18, 'food_encourage', 'Cherries', NULL, NULL, NULL, 'recommended', 'Cherries reduce gout flare frequency', 'ACR 2020'),
(18, 'nutrient_limit', 'Fluid', 2500, NULL, 'ml/day', 'recommended', 'High fluid intake to flush uric acid', 'ACR 2020'),

-- Obesity (condition 19)
(19, 'nutrient_limit', 'Calories', NULL, NULL, 'kcal/day', 'critical', 'Caloric deficit of 500-750 kcal/day', 'WHO 2023'),
(19, 'food_encourage', 'High-fiber foods', 30, NULL, 'g/day', 'recommended', 'Fiber promotes satiety', 'WHO 2023'),
(19, 'food_restrict', 'Ultra-processed foods', NULL, NULL, NULL, 'recommended', 'High calorie density, low nutrition', 'WHO 2023'),

-- Dyslipidemia (condition 20)
(20, 'nutrient_limit', 'Saturated Fat', NULL, NULL, '%kcal', 'critical', '<7% of calories from saturated fat', 'AHA 2023'),
(20, 'nutrient_limit', 'Trans Fat', NULL, 0, 'g/day', 'critical', 'Eliminate trans fats', 'AHA 2023'),
(20, 'food_encourage', 'Omega-3 rich fish', NULL, NULL, NULL, 'recommended', '2+ servings/week of fatty fish', 'AHA 2023'),

-- HIV/AIDS (condition 21)
(21, 'nutrient_limit', 'Protein', 75, NULL, 'g/day', 'critical', 'High protein for immune support', 'WHO HIV Nutrition 2016'),
(21, 'nutrient_limit', 'Calories', NULL, NULL, 'kcal/day', 'recommended', '10-30% increase depending on stage', 'WHO HIV Nutrition 2016'),
(21, 'food_encourage', 'Iron-rich foods', NULL, NULL, NULL, 'recommended', 'Combat anemia common in HIV', 'WHO HIV Nutrition 2016'),
(21, 'food_encourage', 'Vitamin A-rich foods', NULL, NULL, NULL, 'recommended', 'Support immune function', 'WHO HIV Nutrition 2016'),

-- Sickle Cell Disease (condition 22)
(22, 'nutrient_limit', 'Fluid', 3000, NULL, 'ml/day', 'critical', 'High hydration to prevent sickling crises', 'ASH 2020'),
(22, 'nutrient_limit', 'Folic Acid', 1000, NULL, 'mcg/day', 'critical', 'High folate for red blood cell production', 'ASH 2020'),
(22, 'food_encourage', 'Iron-rich foods', NULL, NULL, NULL, 'recommended', 'Support hemoglobin production', 'ASH 2020'),

-- Pregnancy (condition 26)
(26, 'nutrient_limit', 'Folic Acid', 600, NULL, 'mcg/day', 'critical', 'Prevent neural tube defects', 'ACOG 2023'),
(26, 'nutrient_limit', 'Iron', 27, NULL, 'mg/day', 'critical', 'Increased iron need during pregnancy', 'ACOG 2023'),
(26, 'nutrient_limit', 'Calcium', 1000, NULL, 'mg/day', 'critical', 'Bone development + preeclampsia prevention', 'ACOG 2023'),
(26, 'nutrient_limit', 'Calories', NULL, NULL, 'kcal/day', 'recommended', '+340 kcal/day 2nd tri, +452 3rd tri', 'ACOG 2023'),
(26, 'food_restrict', 'Raw/undercooked meat', NULL, NULL, NULL, 'critical', 'Listeria/toxoplasma risk', 'ACOG 2023'),
(26, 'food_restrict', 'High-mercury fish', NULL, NULL, NULL, 'critical', 'Mercury harm to fetal development', 'ACOG 2023'),
(26, 'food_restrict', 'Alcohol', NULL, 0, 'drinks/day', 'critical', 'No safe level of alcohol in pregnancy', 'ACOG 2023'),

-- Anemia (condition 29)
(29, 'nutrient_limit', 'Iron', 18, NULL, 'mg/day', 'critical', 'Increase iron intake', 'WHO 2023'),
(29, 'nutrient_limit', 'Vitamin C', 75, NULL, 'mg/day', 'recommended', 'Vitamin C enhances iron absorption', 'WHO 2023'),
(29, 'food_encourage', 'Leafy greens', NULL, NULL, NULL, 'recommended', 'Rich in non-heme iron', 'WHO 2023'),
(29, 'food_restrict', 'Tea with meals', NULL, NULL, NULL, 'recommended', 'Tannins inhibit iron absorption', 'WHO 2023'),

-- Healthy / No Condition (condition 30)
(30, 'nutrient_limit', 'Sodium', NULL, 2300, 'mg/day', 'recommended', 'General sodium guideline', 'WHO 2023'),
(30, 'nutrient_limit', 'Added Sugar', NULL, 50, 'g/day', 'recommended', '<10% of calories from added sugar', 'WHO 2023'),
(30, 'nutrient_limit', 'Fiber', 25, NULL, 'g/day', 'recommended', 'General fiber recommendation', 'WHO 2023'),
(30, 'food_encourage', 'Fruits and Vegetables', NULL, NULL, NULL, 'recommended', '5+ servings per day', 'WHO 2023');

-- ============================================================================
-- SEED: ONBOARDING FLOW QUESTIONS (~15 entries)
-- ============================================================================

INSERT OR IGNORE INTO condition_onboarding_flow (condition_id, question_text, question_type, options, is_required, sequence_order, maps_to_field) VALUES
-- Universal questions (condition_id NULL = all)
(NULL, 'Do you have any diagnosed medical conditions?', 'single_choice', '["Yes","No","Not sure"]', TRUE, 1, 'has_condition'),
(NULL, 'When were you diagnosed?', 'date', NULL, FALSE, 2, 'diagnosed_date'),
(NULL, 'Are you currently on any medications?', 'single_choice', '["Yes","No"]', TRUE, 3, 'on_medications'),
(NULL, 'Do you see a doctor regularly for this condition?', 'single_choice', '["Yes, regularly","Sometimes","No"]', FALSE, 4, 'has_regular_doctor'),

-- CKD-specific (condition 1-9, using representative condition 3)
(3, 'What is your current CKD stage?', 'single_choice', '["Stage 1","Stage 2","Stage 3a","Stage 3b","Stage 4","Stage 5","On Dialysis","Not sure"]', TRUE, 5, 'stage'),
(3, 'Are you on dialysis?', 'single_choice', '["Hemodialysis","Peritoneal Dialysis","No","Planning to start"]', TRUE, 6, 'dialysis_type'),
(3, 'What is your most recent eGFR?', 'number', NULL, FALSE, 7, 'last_egfr'),

-- Diabetes-specific (condition 10-13)
(11, 'How do you manage your diabetes?', 'multi_choice', '["Diet only","Oral medications","Insulin","Insulin pump","CGM"]', TRUE, 5, 'management_method'),
(11, 'What is your most recent HbA1c?', 'number', NULL, FALSE, 6, 'last_hba1c'),

-- Hypertension-specific
(14, 'What is your typical blood pressure?', 'text', NULL, FALSE, 5, 'typical_bp'),
(14, 'Are you on blood pressure medications?', 'single_choice', '["Yes","No"]', TRUE, 6, 'on_bp_meds'),

-- Pregnancy-specific
(26, 'How many weeks pregnant are you?', 'number', NULL, TRUE, 5, 'gestational_weeks'),
(26, 'Is this a high-risk pregnancy?', 'single_choice', '["Yes","No","Not sure"]', TRUE, 6, 'high_risk'),

-- General wellness
(30, 'What is your primary health goal?', 'single_choice', '["Weight loss","Weight gain","General wellness","Sports performance","Disease prevention"]', TRUE, 5, 'health_goal'),
(30, 'How would you rate your current diet?', 'single_choice', '["Poor","Fair","Good","Excellent"]', FALSE, 6, 'diet_rating');

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT 'medical_conditions' AS tbl, COUNT(*) AS rows FROM medical_conditions
UNION ALL
SELECT 'condition_game_modifiers', COUNT(*) FROM condition_game_modifiers
UNION ALL
SELECT 'condition_nutrition_rules', COUNT(*) FROM condition_nutrition_rules
UNION ALL
SELECT 'condition_onboarding_flow', COUNT(*) FROM condition_onboarding_flow;
