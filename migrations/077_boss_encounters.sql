-- Migration 077: Boss Encounters
-- Pro-only feature: Health condition bosses defeated by real health actions
-- Bosses linked to conditions via condition_game_modifiers

-- ============================================================================
-- BOSS ENCOUNTERS
-- ============================================================================

CREATE TABLE IF NOT EXISTS boss_encounters (
    id INTEGER PRIMARY KEY,
    boss_name VARCHAR(80) NOT NULL UNIQUE,
    boss_title VARCHAR(120),
    description TEXT NOT NULL,
    condition_focus VARCHAR(60),
        -- CKD, Diabetes, Hypertension, General, etc.
    base_hp INTEGER NOT NULL,
        -- Base hit points (scales with condition severity)
    difficulty_level INTEGER NOT NULL DEFAULT 1,
        -- 1=Normal, 2=Hard, 3=Nightmare
    respawn_days INTEGER DEFAULT 30,
        -- Days before boss can be fought again (harder)
    difficulty_scaling REAL DEFAULT 1.5,
        -- HP multiplier on respawn
    min_level_required INTEGER DEFAULT 5,
    requires_subscription_tier INTEGER DEFAULT 3,
    xp_reward_base INTEGER NOT NULL,
    ap_reward_base INTEGER DEFAULT 0,
    icon VARCHAR(60),
    lore_text TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- BOSS MECHANICS (How to defeat each boss)
-- ============================================================================

CREATE TABLE IF NOT EXISTS boss_mechanics (
    id INTEGER PRIMARY KEY,
    boss_id INTEGER NOT NULL REFERENCES boss_encounters(id),
    mechanic_type VARCHAR(40) NOT NULL,
        -- nutrient_control, med_adherence, lab_improvement, streak,
        -- hydration, exercise, logging, biometric_target
    target_metric VARCHAR(60) NOT NULL,
        -- e.g., 'daily_potassium_mg', 'bp_systolic', 'glucose_fasting'
    target_operator VARCHAR(10) NOT NULL DEFAULT '<=',
        -- <=, >=, ==, between
    target_value REAL NOT NULL,
    target_value_upper REAL,
        -- For 'between' operator
    required_days INTEGER DEFAULT 7,
        -- How many days to sustain this to deal damage
    damage_per_success INTEGER NOT NULL,
        -- HP damage dealt per day of compliance
    description TEXT NOT NULL,
    sequence_order INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- BOSS LOOT TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS boss_loot_table (
    id INTEGER PRIMARY KEY,
    boss_id INTEGER NOT NULL REFERENCES boss_encounters(id),
    loot_type VARCHAR(40) NOT NULL,
        -- xp, afya_points, cosmetic, title, crafting_material, pet_treat
    loot_value INTEGER,
    loot_item_id INTEGER,
    loot_name VARCHAR(80),
    drop_chance_pct REAL DEFAULT 100.0,
        -- 100 = guaranteed, <100 = random chance
    is_first_kill_only BOOLEAN DEFAULT FALSE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- USER BOSS PROGRESS
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_boss_progress (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    boss_id INTEGER NOT NULL REFERENCES boss_encounters(id),
    status VARCHAR(20) NOT NULL DEFAULT 'locked',
        -- locked, available, active, defeated, respawning
    current_boss_hp INTEGER,
    damage_dealt INTEGER DEFAULT 0,
    attempt_number INTEGER DEFAULT 1,
    highest_difficulty_defeated INTEGER DEFAULT 0,
    started_at TIMESTAMP,
    defeated_at TIMESTAMP,
    respawn_at TIMESTAMP,
    total_defeats INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, boss_id)
);

-- ============================================================================
-- BOSS CONDITION LINKS (which conditions unlock which bosses)
-- ============================================================================

CREATE TABLE IF NOT EXISTS boss_condition_links (
    id INTEGER PRIMARY KEY,
    boss_id INTEGER NOT NULL REFERENCES boss_encounters(id),
    condition_id INTEGER NOT NULL REFERENCES medical_conditions(id),
    unlock_at_stage VARCHAR(20),
        -- e.g., 'Stage 3a' for CKD bosses
    hp_modifier REAL DEFAULT 1.0,
        -- Condition-specific HP scaling
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(boss_id, condition_id)
);

-- ============================================================================
-- SEED: 15 BOSS ENCOUNTERS
-- ============================================================================

INSERT OR IGNORE INTO boss_encounters (id, boss_name, boss_title, description, condition_focus, base_hp, difficulty_level, respawn_days, min_level_required, requires_subscription_tier, xp_reward_base, ap_reward_base, icon, lore_text) VALUES
-- CKD Bosses
(1, 'Phosphorus Phantom', 'The Bone Destroyer',
 'A spectral entity that feeds on excess phosphorus, weakening bones and calcifying blood vessels. Defeat it by maintaining strict phosphorus control.',
 'CKD', 500, 1, 30, 8, 3, 200, 50, 'ghost_purple',
 'Born from the imbalance of minerals in weakened kidneys, the Phosphorus Phantom haunts those who neglect their phosphorus intake.'),

(2, 'Potassium Kraken', 'The Heart Stopper',
 'A massive tentacled beast lurking in the deep, powered by excess potassium. Keep your K+ controlled to weaken its grip.',
 'CKD', 700, 2, 30, 12, 3, 350, 80, 'kraken_orange',
 'The Potassium Kraken thrives in seas of excess potassium. Its tentacles reach for the heart, threatening deadly arrhythmias.'),

(3, 'Uremia Dragon', 'The Waste Accumulator',
 'A fearsome dragon breathing toxic uremic waste. Only strict CKD diet compliance can pierce its scales.',
 'CKD', 1000, 3, 45, 18, 3, 500, 120, 'dragon_green',
 'The mightiest CKD boss. The Uremia Dragon grows from accumulated waste that failing kidneys cannot clear.'),

(4, 'Fluid Overload Titan', 'The Drowning Giant',
 'A colossal water elemental that swells with every excess drop. Track your fluid intake to drain its power.',
 'CKD', 600, 2, 30, 10, 3, 300, 70, 'titan_blue',
 'Between dialysis sessions, the Fluid Overload Titan grows, pressing on lungs and heart.'),

-- Diabetes Bosses
(5, 'Sugar Dragon', 'The Glucose Inferno',
 'A fire-breathing dragon fueled by blood sugar spikes. Maintain glucose control to extinguish its flames.',
 'Diabetes', 600, 1, 30, 8, 3, 250, 60, 'dragon_red',
 'The Sugar Dragon ignites when glucose runs unchecked, scorching blood vessels and nerves in its path.'),

(6, 'Insulin Resistance Golem', 'The Metabolic Wall',
 'A massive stone construct built from metabolic dysfunction. Break it down with exercise, low-GI foods, and medication adherence.',
 'Diabetes', 800, 2, 30, 12, 3, 350, 80, 'golem_brown',
 'Brick by brick, the Insulin Resistance Golem was built from years of metabolic neglect. Only sustained effort can topple it.'),

-- Hypertension Bosses
(7, 'BP Storm Giant', 'The Pressure Crusher',
 'A towering storm elemental whose power surges with blood pressure. Keep your BP controlled to calm the storm.',
 'Hypertension', 600, 1, 30, 8, 3, 250, 60, 'giant_grey',
 'The BP Storm Giant materializes from unchecked blood pressure, each spike a thunderbolt that damages arteries.'),

(8, 'Salt Golem', 'The Sodium Sentinel',
 'A crystalline golem formed from excess sodium. Reduce your salt intake to dissolve its armor.',
 'Hypertension', 500, 1, 30, 6, 3, 200, 50, 'golem_white',
 'In the mines of excess sodium, the Salt Golem grows. Every gram of salt consumed adds to its impenetrable shell.'),

-- Metabolic Bosses
(9, 'Cholesterol Hydra', 'The Artery Blocker',
 'A multi-headed serpent that clogs arteries. Cut off its heads with healthy fats and exercise.',
 'Cardiovascular', 700, 2, 30, 10, 3, 300, 70, 'hydra_yellow',
 'Each head of the Cholesterol Hydra represents a different lipid: LDL, triglycerides, VLDL. Cut them all.'),

(10, 'Uric Acid Titan', 'The Crystal Crusher',
 'A crystal-covered titan whose joints are weapons. Low-purine diet and hydration weaken its crystal armor.',
 'Gout', 500, 1, 30, 8, 3, 200, 50, 'titan_crystal',
 'Uric acid crystals form the Titan''s armor - sharp, painful, and relentless. Only discipline can shatter them.'),

-- General Health Bosses
(11, 'Calorie Overlord', 'The Excess Emperor',
 'An enormous entity that grows with every excess calorie. Hit your calorie targets to shrink it.',
 'General', 500, 1, 30, 5, 3, 200, 50, 'emperor_gold',
 'The Calorie Overlord expands endlessly, consuming all in its path. Only measured eating can contain it.'),

(12, 'Sedentary Shadow', 'The Stillness Specter',
 'A dark shade that feeds on inactivity. Movement and exercise are its bane.',
 'General', 400, 1, 21, 3, 3, 150, 40, 'shadow_dark',
 'Born from hours on the couch, the Sedentary Shadow drains energy and vitality from the inactive.'),

(13, 'Dehydration Wraith', 'The Thirst Phantom',
 'A withered specter that drains moisture. Stay hydrated to banish it.',
 'General', 350, 1, 21, 3, 3, 150, 40, 'wraith_dry',
 'The Dehydration Wraith lurks in hot African climates, waiting for those who forget to drink water.'),

(14, 'Iron Deficiency Specter', 'The Pale Haunter',
 'A ghostly apparition born from iron-poor blood. Consume iron-rich foods to strengthen against it.',
 'Hematological', 400, 1, 30, 5, 3, 175, 45, 'specter_pale',
 'Pale and draining, the Iron Deficiency Specter saps strength from those whose blood runs thin.'),

(15, 'Medication Skip Demon', 'The Forgetful Fiend',
 'A trickster demon that makes you forget your medications. Perfect adherence is its weakness.',
 'General', 450, 1, 14, 5, 3, 200, 50, 'demon_purple',
 'The Medication Skip Demon whispers excuses: "You can skip today." But each skip makes it stronger.');

-- ============================================================================
-- SEED: BOSS MECHANICS
-- ============================================================================

-- Phosphorus Phantom mechanics
INSERT OR IGNORE INTO boss_mechanics (boss_id, mechanic_type, target_metric, target_operator, target_value, required_days, damage_per_success, description, sequence_order) VALUES
(1, 'nutrient_control', 'daily_phosphorus_mg', '<=', 800, 7, 70, 'Keep daily phosphorus under 800mg for 7 days', 1),
(1, 'med_adherence', 'phosphate_binder_adherence', '>=', 90, 7, 50, 'Take phosphate binders 90%+ of the time', 2);

-- Potassium Kraken mechanics
INSERT OR IGNORE INTO boss_mechanics (boss_id, mechanic_type, target_metric, target_operator, target_value, required_days, damage_per_success, description, sequence_order) VALUES
(2, 'nutrient_control', 'daily_potassium_mg', '<=', 2000, 7, 80, 'Keep daily potassium under 2000mg for 7 days', 1),
(2, 'lab_improvement', 'potassium_serum', 'between', 3.5, 7, 100, 'Keep serum K+ between 3.5-5.0 mEq/L', 2);
UPDATE boss_mechanics SET target_value_upper = 5.0 WHERE boss_id = 2 AND mechanic_type = 'lab_improvement';

-- Uremia Dragon mechanics
INSERT OR IGNORE INTO boss_mechanics (boss_id, mechanic_type, target_metric, target_operator, target_value, required_days, damage_per_success, description, sequence_order) VALUES
(3, 'nutrient_control', 'daily_protein_g', '<=', 60, 14, 50, 'Keep protein intake controlled for 14 days', 1),
(3, 'nutrient_control', 'daily_pral', '<=', 0, 14, 40, 'Maintain alkalizing diet (PRAL ≤ 0) for 14 days', 2),
(3, 'med_adherence', 'all_ckd_meds', '>=', 95, 14, 60, '95%+ adherence to all CKD medications', 3);

-- Fluid Overload Titan mechanics
INSERT OR IGNORE INTO boss_mechanics (boss_id, mechanic_type, target_metric, target_operator, target_value, required_days, damage_per_success, description, sequence_order) VALUES
(4, 'hydration', 'daily_fluid_ml', '<=', 1500, 7, 80, 'Keep fluid intake under 1500ml/day', 1),
(4, 'biometric_target', 'weight_change_kg', '<=', 2, 7, 60, 'Interdialytic weight gain < 2kg', 2);

-- Sugar Dragon mechanics
INSERT OR IGNORE INTO boss_mechanics (boss_id, mechanic_type, target_metric, target_operator, target_value, required_days, damage_per_success, description, sequence_order) VALUES
(5, 'biometric_target', 'glucose_fasting', '<=', 130, 7, 80, 'Fasting glucose under 130 mg/dL for 7 days', 1),
(5, 'nutrient_control', 'glycemic_load', '<=', 100, 7, 60, 'Daily glycemic load under 100', 2);

-- Insulin Resistance Golem mechanics
INSERT OR IGNORE INTO boss_mechanics (boss_id, mechanic_type, target_metric, target_operator, target_value, required_days, damage_per_success, description, sequence_order) VALUES
(6, 'biometric_target', 'glucose_postmeal', '<=', 180, 10, 60, 'Post-meal glucose under 180 mg/dL', 1),
(6, 'exercise', 'weekly_exercise_minutes', '>=', 150, 10, 50, '150+ minutes exercise per week', 2),
(6, 'med_adherence', 'diabetes_meds', '>=', 90, 10, 50, '90%+ diabetes medication adherence', 3);

-- BP Storm Giant mechanics
INSERT OR IGNORE INTO boss_mechanics (boss_id, mechanic_type, target_metric, target_operator, target_value, required_days, damage_per_success, description, sequence_order) VALUES
(7, 'biometric_target', 'bp_systolic', '<=', 140, 7, 80, 'Systolic BP under 140 mmHg for 7 days', 1),
(7, 'med_adherence', 'bp_meds', '>=', 90, 7, 60, '90%+ BP medication adherence', 2);

-- Salt Golem mechanics
INSERT OR IGNORE INTO boss_mechanics (boss_id, mechanic_type, target_metric, target_operator, target_value, required_days, damage_per_success, description, sequence_order) VALUES
(8, 'nutrient_control', 'daily_sodium_mg', '<=', 2000, 7, 70, 'Daily sodium under 2000mg for 7 days', 1),
(8, 'logging', 'meals_logged', '>=', 3, 7, 50, 'Log all 3 meals daily with sodium tracking', 2);

-- Cholesterol Hydra mechanics
INSERT OR IGNORE INTO boss_mechanics (boss_id, mechanic_type, target_metric, target_operator, target_value, required_days, damage_per_success, description, sequence_order) VALUES
(9, 'nutrient_control', 'daily_saturated_fat_pct', '<=', 7, 10, 60, 'Saturated fat under 7% of calories', 1),
(9, 'exercise', 'weekly_exercise_minutes', '>=', 150, 10, 50, '150+ minutes exercise per week', 2),
(9, 'lab_improvement', 'ldl_cholesterol', '<=', 100, 10, 70, 'LDL cholesterol under 100 mg/dL', 3);

-- Uric Acid Titan mechanics
INSERT OR IGNORE INTO boss_mechanics (boss_id, mechanic_type, target_metric, target_operator, target_value, required_days, damage_per_success, description, sequence_order) VALUES
(10, 'nutrient_control', 'purine_intake', '<=', 200, 7, 70, 'Keep purine intake low for 7 days', 1),
(10, 'hydration', 'daily_water_glasses', '>=', 10, 7, 60, 'Drink 10+ glasses of water daily', 2);

-- Calorie Overlord mechanics
INSERT OR IGNORE INTO boss_mechanics (boss_id, mechanic_type, target_metric, target_operator, target_value, required_days, damage_per_success, description, sequence_order) VALUES
(11, 'nutrient_control', 'calorie_target_pct', 'between', 90, 7, 70, 'Stay within 90-110% of calorie target', 1);
UPDATE boss_mechanics SET target_value_upper = 110 WHERE boss_id = 11 AND mechanic_type = 'nutrient_control';

-- Sedentary Shadow mechanics
INSERT OR IGNORE INTO boss_mechanics (boss_id, mechanic_type, target_metric, target_operator, target_value, required_days, damage_per_success, description, sequence_order) VALUES
(12, 'exercise', 'daily_steps', '>=', 5000, 5, 80, 'Walk 5000+ steps daily for 5 days', 1),
(12, 'exercise', 'active_minutes', '>=', 30, 5, 60, '30+ minutes active per day', 2);

-- Dehydration Wraith mechanics
INSERT OR IGNORE INTO boss_mechanics (boss_id, mechanic_type, target_metric, target_operator, target_value, required_days, damage_per_success, description, sequence_order) VALUES
(13, 'hydration', 'daily_water_glasses', '>=', 8, 5, 70, 'Drink 8+ glasses of water daily', 1);

-- Iron Deficiency Specter mechanics
INSERT OR IGNORE INTO boss_mechanics (boss_id, mechanic_type, target_metric, target_operator, target_value, required_days, damage_per_success, description, sequence_order) VALUES
(14, 'nutrient_control', 'daily_iron_mg', '>=', 18, 7, 55, 'Consume 18+ mg iron daily for 7 days', 1),
(14, 'nutrient_control', 'daily_vitamin_c_mg', '>=', 75, 7, 45, 'Consume 75+ mg vitamin C daily (enhances absorption)', 2);

-- Medication Skip Demon mechanics
INSERT OR IGNORE INTO boss_mechanics (boss_id, mechanic_type, target_metric, target_operator, target_value, required_days, damage_per_success, description, sequence_order) VALUES
(15, 'med_adherence', 'all_meds', '==', 100, 7, 65, 'Perfect 100% medication adherence for 7 days', 1);

-- ============================================================================
-- SEED: BOSS LOOT
-- ============================================================================

INSERT OR IGNORE INTO boss_loot_table (boss_id, loot_type, loot_value, loot_name, drop_chance_pct, is_first_kill_only, description) VALUES
-- Phosphorus Phantom loot
(1, 'xp', 200, 'Phantom XP', 100, FALSE, 'XP for defeating Phosphorus Phantom'),
(1, 'afya_points', 50, 'Phantom Coins', 100, FALSE, 'AP reward'),
(1, 'title', NULL, 'Phosphorus Slayer', 100, TRUE, 'Title: Phosphorus Slayer (first kill only)'),
(1, 'cosmetic', 1, 'Phantom Cloak', 25, FALSE, '25% chance of rare cosmetic drop'),

-- Potassium Kraken loot
(2, 'xp', 350, 'Kraken XP', 100, FALSE, 'XP for defeating Potassium Kraken'),
(2, 'afya_points', 80, 'Kraken Treasure', 100, FALSE, 'AP reward'),
(2, 'title', NULL, 'Kraken Conqueror', 100, TRUE, 'Title: Kraken Conqueror'),
(2, 'cosmetic', 2, 'Kraken Tentacle Cape', 20, FALSE, '20% chance of rare cosmetic'),

-- Uremia Dragon loot
(3, 'xp', 500, 'Dragon XP', 100, FALSE, 'XP for defeating Uremia Dragon'),
(3, 'afya_points', 120, 'Dragon Hoard', 100, FALSE, 'AP reward'),
(3, 'title', NULL, 'Dragon Slayer', 100, TRUE, 'Title: Dragon Slayer'),
(3, 'cosmetic', 3, 'Dragon Scale Armor', 15, FALSE, '15% chance of legendary cosmetic'),

-- Sugar Dragon loot
(5, 'xp', 250, 'Sweet Victory XP', 100, FALSE, 'XP for defeating Sugar Dragon'),
(5, 'afya_points', 60, 'Sugar-Free Gold', 100, FALSE, 'AP reward'),
(5, 'title', NULL, 'Sugar Slayer', 100, TRUE, 'Title: Sugar Slayer'),

-- BP Storm Giant loot
(7, 'xp', 250, 'Storm XP', 100, FALSE, 'XP for defeating BP Storm Giant'),
(7, 'afya_points', 60, 'Storm Crystals', 100, FALSE, 'AP reward'),
(7, 'title', NULL, 'Storm Breaker', 100, TRUE, 'Title: Storm Breaker'),

-- General boss loot (Sedentary Shadow, Dehydration Wraith, etc.)
(12, 'xp', 150, 'Shadow XP', 100, FALSE, 'XP for defeating Sedentary Shadow'),
(12, 'title', NULL, 'Shadow Banisher', 100, TRUE, 'Title: Shadow Banisher'),
(13, 'xp', 150, 'Wraith XP', 100, FALSE, 'XP for defeating Dehydration Wraith'),
(13, 'title', NULL, 'Hydration Hero', 100, TRUE, 'Title: Hydration Hero'),
(15, 'xp', 200, 'Demon XP', 100, FALSE, 'XP for defeating Medication Skip Demon'),
(15, 'title', NULL, 'The Adherent', 100, TRUE, 'Title: The Adherent');

-- ============================================================================
-- SEED: BOSS-CONDITION LINKS
-- ============================================================================

INSERT OR IGNORE INTO boss_condition_links (boss_id, condition_id, unlock_at_stage, hp_modifier, description) VALUES
-- CKD bosses
(1, 3, 'Stage 3a', 1.0, 'CKD Stage 3a: Phosphorus Phantom unlocked'),
(1, 4, 'Stage 3b', 1.2, 'CKD Stage 3b: Phantom is stronger'),
(1, 5, 'Stage 4', 1.5, 'CKD Stage 4: Phantom is much stronger'),
(2, 5, 'Stage 4', 1.0, 'CKD Stage 4: Potassium Kraken unlocked'),
(2, 6, 'Stage 5', 1.3, 'CKD Stage 5: Kraken is stronger'),
(2, 7, NULL, 1.5, 'Hemodialysis: Kraken is at full power'),
(3, 6, 'Stage 5', 1.0, 'CKD Stage 5: Uremia Dragon unlocked'),
(3, 7, NULL, 1.2, 'Hemodialysis: Dragon is stronger'),
(4, 7, NULL, 1.0, 'Hemodialysis: Fluid Overload Titan unlocked'),
(4, 8, NULL, 1.0, 'Peritoneal Dialysis: Fluid Overload Titan unlocked'),
(4, 16, NULL, 1.2, 'Heart Failure: Fluid Titan is stronger'),

-- Diabetes bosses
(5, 10, NULL, 1.2, 'Type 1 Diabetes: Sugar Dragon is stronger'),
(5, 11, NULL, 1.0, 'Type 2 Diabetes: Sugar Dragon unlocked'),
(5, 13, NULL, 0.7, 'Pre-Diabetes: Sugar Dragon is weaker (early warning)'),
(6, 11, NULL, 1.0, 'Type 2 Diabetes: Insulin Resistance Golem unlocked'),

-- Hypertension bosses
(7, 14, 'Stage 1', 1.0, 'HTN Stage 1: BP Storm Giant unlocked'),
(7, 15, 'Stage 2', 1.3, 'HTN Stage 2: Storm Giant is stronger'),
(8, 14, 'Stage 1', 1.0, 'HTN Stage 1: Salt Golem unlocked'),
(8, 15, 'Stage 2', 1.2, 'HTN Stage 2: Salt Golem is stronger'),

-- Other condition-specific bosses
(9, 17, NULL, 1.0, 'CAD: Cholesterol Hydra unlocked'),
(9, 20, NULL, 0.8, 'Dyslipidemia: Hydra is present but weaker'),
(10, 18, NULL, 1.0, 'Gout: Uric Acid Titan unlocked'),
(14, 29, NULL, 1.0, 'Anemia: Iron Deficiency Specter unlocked'),
(14, 22, NULL, 1.2, 'Sickle Cell: Specter is stronger'),
(13, 22, NULL, 1.0, 'Sickle Cell: Dehydration Wraith unlocked');

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT 'boss_encounters' AS tbl, COUNT(*) AS rows FROM boss_encounters
UNION ALL
SELECT 'boss_mechanics', COUNT(*) FROM boss_mechanics
UNION ALL
SELECT 'boss_loot_table', COUNT(*) FROM boss_loot_table
UNION ALL
SELECT 'boss_condition_links', COUNT(*) FROM boss_condition_links
UNION ALL
SELECT 'user_boss_progress', COUNT(*) FROM user_boss_progress;
