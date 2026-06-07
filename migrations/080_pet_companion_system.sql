-- Migration 080: Pet/Companion System
-- Virtual health companions - Pan-African animals
-- Pet health reflects owner's health behaviors (motivation mechanic)
-- Free: no pets. Plus: 1 pet. Pro: 3 pets.

-- ============================================================================
-- PET SPECIES (8 Pan-African animals)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pet_species (
    id INTEGER PRIMARY KEY,
    species_name VARCHAR(60) NOT NULL UNIQUE,
    display_name VARCHAR(80) NOT NULL,
    description TEXT NOT NULL,
    native_region VARCHAR(60),
    base_happiness INTEGER DEFAULT 50,
    base_health INTEGER DEFAULT 100,
    condition_affinity VARCHAR(60),
        -- Which health condition this pet is especially good for
    special_ability_description TEXT,
    requires_subscription_tier INTEGER DEFAULT 2,
    icon VARCHAR(60),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- PET EVOLUTION STAGES (4 per species)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pet_evolution_stages (
    id INTEGER PRIMARY KEY,
    species_id INTEGER NOT NULL REFERENCES pet_species(id),
    stage_name VARCHAR(40) NOT NULL,
    stage_level INTEGER NOT NULL,
        -- 1=Baby, 2=Juvenile, 3=Adult, 4=Mythic
    required_owner_streak INTEGER DEFAULT 0,
        -- Days of consecutive healthy behavior
    required_owner_level INTEGER DEFAULT 1,
    required_pet_happiness INTEGER DEFAULT 0,
    appearance_description TEXT,
    stat_bonus_type VARCHAR(40),
        -- xp_boost, reminder, rare_find, crafting_boost, social_boost
    stat_bonus_value REAL DEFAULT 0,
    unlock_message TEXT,
    icon VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(species_id, stage_level)
);

-- ============================================================================
-- USER PETS
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_pets (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    species_id INTEGER NOT NULL REFERENCES pet_species(id),
    pet_name VARCHAR(60) NOT NULL,
    current_stage INTEGER DEFAULT 1,
    happiness INTEGER DEFAULT 50,
        -- 0-100 scale
    health INTEGER DEFAULT 100,
        -- 0-100 scale
    hunger INTEGER DEFAULT 50,
        -- 0=starving, 100=full
    is_active BOOLEAN DEFAULT TRUE,
        -- Active companion (shown on profile)
    is_favorite BOOLEAN DEFAULT FALSE,
    total_care_actions INTEGER DEFAULT 0,
    total_days_owned INTEGER DEFAULT 0,
    last_fed_at TIMESTAMP,
    last_played_at TIMESTAMP,
    last_healed_at TIMESTAMP,
    adopted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- PET CARE ACTIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS pet_care_actions (
    id INTEGER PRIMARY KEY,
    action_name VARCHAR(60) NOT NULL UNIQUE,
    action_type VARCHAR(40) NOT NULL,
        -- feed, play, heal, train, groom
    trigger_event VARCHAR(60) NOT NULL,
        -- meal_logged, exercise_logged, med_taken, lab_uploaded, hydration_logged,
        -- quest_completed, boss_defeated, guild_contributed
    happiness_change INTEGER DEFAULT 0,
    health_change INTEGER DEFAULT 0,
    hunger_change INTEGER DEFAULT 0,
    xp_reward INTEGER DEFAULT 5,
    description TEXT,
    cooldown_hours INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- PET ABILITIES (unlocked per evolution stage)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pet_abilities (
    id INTEGER PRIMARY KEY,
    species_id INTEGER NOT NULL REFERENCES pet_species(id),
    stage_level INTEGER NOT NULL,
    ability_name VARCHAR(80) NOT NULL,
    ability_type VARCHAR(40) NOT NULL,
        -- passive_xp_boost, reminder, rare_item_find, crafting_quality_boost,
        -- social_xp_boost, med_reminder, nutrient_alert
    ability_value REAL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(species_id, stage_level, ability_type)
);

-- ============================================================================
-- PET DECAY RULES (pet health decays if owner stops healthy behaviors)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pet_decay_rules (
    id INTEGER PRIMARY KEY,
    decay_trigger VARCHAR(60) NOT NULL UNIQUE,
        -- no_meal_24h, no_login_48h, missed_medication, broken_streak,
        -- no_exercise_72h, no_hydration_24h
    happiness_decay INTEGER DEFAULT -5,
    health_decay INTEGER DEFAULT -3,
    hunger_decay INTEGER DEFAULT -10,
    decay_interval_hours INTEGER DEFAULT 24,
        -- How often this decay applies
    recovery_action VARCHAR(60),
        -- What action reverses the decay
    warning_message TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- SEED: 8 PET SPECIES
-- ============================================================================

INSERT OR IGNORE INTO pet_species (id, species_name, display_name, description, native_region, base_happiness, base_health, condition_affinity, special_ability_description, requires_subscription_tier, icon) VALUES
(1, 'afya_owl', 'Afya Owl', 'A wise owl that watches over your health journey. Known for its knowledge of nutrition and timing of medications.',
 'Pan-African', 60, 100, 'General', 'Medication reminders + nutrition tips', 2, 'owl_gold'),

(2, 'bongo_antelope', 'Bongo Antelope', 'A rare forest antelope from Central Africa. Graceful and strong, it thrives on balanced nutrition.',
 'Central Africa', 50, 100, 'CKD', 'Potassium/phosphorus alerts when food is logged', 2, 'bongo_brown'),

(3, 'chameleon', 'Rainbow Chameleon', 'A color-changing chameleon that reflects your health status. Green = healthy, yellow = watch out, red = danger.',
 'East Africa', 55, 100, 'Diabetes', 'Color changes based on glucose control', 2, 'chameleon_green'),

(4, 'dik_dik', 'Dik-Dik', 'A tiny antelope from the horn of Africa. Small but mighty, it tracks every step you take.',
 'East Africa', 65, 100, 'Hypertension', 'Step counting + exercise motivation', 2, 'dikdik_tan'),

(5, 'fish_eagle', 'African Fish Eagle', 'The majestic fish eagle sees everything from above. It scouts for the best foods and health opportunities.',
 'Pan-African', 45, 100, 'Cardiovascular', 'Rare crafting material finder', 2, 'eagle_white'),

(6, 'flamingo', 'Greater Flamingo', 'A pink flamingo whose color depends on your hydration. Stay hydrated to keep it bright!',
 'East/Southern Africa', 55, 100, 'Hematological', 'Hydration tracking + water reminders', 2, 'flamingo_pink'),

(7, 'silverback', 'Mountain Gorilla', 'A powerful silverback from the Virunga Mountains. Its strength grows with your health consistency.',
 'Central Africa', 40, 100, 'Obesity', 'Strength-based XP boost on exercise logging', 3, 'gorilla_silver'),

(8, 'honey_badger', 'Honey Badger', 'The fearless honey badger never gives up. It boosts your resilience and streak recovery.',
 'Pan-African', 50, 100, 'General', 'Streak protection: 1 missed day forgiven per week', 3, 'badger_grey');

-- ============================================================================
-- SEED: EVOLUTION STAGES (4 per species = 32 entries)
-- ============================================================================

-- Afya Owl evolution
INSERT OR IGNORE INTO pet_evolution_stages (species_id, stage_name, stage_level, required_owner_streak, required_owner_level, required_pet_happiness, appearance_description, stat_bonus_type, stat_bonus_value, unlock_message) VALUES
(1, 'Owlet', 1, 0, 1, 0, 'A small fluffy owlet with big curious eyes', 'reminder', 1, 'Your Afya Owlet has hatched! It will grow as you grow.'),
(1, 'Young Owl', 2, 14, 5, 40, 'A young owl with developing wisdom feathers', 'xp_boost', 3, 'Your owl is growing wiser! +3% XP boost.'),
(1, 'Wise Owl', 3, 60, 12, 65, 'A majestic owl with golden wisdom markings', 'xp_boost', 7, 'The Wise Owl sees all! +7% XP boost + nutrition alerts.'),
(1, 'Mythic Sage Owl', 4, 180, 20, 85, 'A legendary golden owl radiating health wisdom', 'xp_boost', 12, 'MYTHIC! Your Sage Owl is legendary! +12% XP + perfect reminders.');

-- Bongo Antelope evolution
INSERT OR IGNORE INTO pet_evolution_stages (species_id, stage_name, stage_level, required_owner_streak, required_owner_level, required_pet_happiness, appearance_description, stat_bonus_type, stat_bonus_value, unlock_message) VALUES
(2, 'Bongo Calf', 1, 0, 1, 0, 'A wobbly bongo calf with faint stripes', 'reminder', 1, 'A tiny Bongo has joined your journey!'),
(2, 'Young Bongo', 2, 14, 5, 40, 'Stripes deepening, horns starting to show', 'nutrient_alert', 1, 'Your Bongo is growing! It now alerts you about K+ and P.'),
(2, 'Bongo Bull', 3, 60, 12, 65, 'A powerful bongo with magnificent spiraling horns', 'crafting_boost', 10, 'Mighty Bongo Bull! +10% crafting quality on CKD recipes.'),
(2, 'Mythic Forest Spirit', 4, 180, 20, 85, 'A glowing ethereal bongo, guardian of the kidney realm', 'xp_boost', 15, 'MYTHIC! Forest Spirit Bongo! +15% XP on all CKD actions.');

-- Chameleon evolution
INSERT OR IGNORE INTO pet_evolution_stages (species_id, stage_name, stage_level, required_owner_streak, required_owner_level, required_pet_happiness, appearance_description, stat_bonus_type, stat_bonus_value, unlock_message) VALUES
(3, 'Baby Chameleon', 1, 0, 1, 0, 'A tiny chameleon, mostly green', 'reminder', 1, 'A little chameleon has appeared!'),
(3, 'Color Shifter', 2, 14, 5, 40, 'Colors now change with your glucose levels', 'nutrient_alert', 1, 'Your chameleon changes color based on glucose control!'),
(3, 'Prism Chameleon', 3, 60, 12, 65, 'Displays rainbow spectrum based on overall health', 'xp_boost', 8, 'Prism Chameleon! +8% XP + visual health status display.'),
(3, 'Mythic Spectrum Dragon', 4, 180, 20, 85, 'A miniature dragon-like chameleon with prismatic scales', 'xp_boost', 15, 'MYTHIC! Spectrum Dragon! +15% XP on all diabetes actions.');

-- Dik-Dik evolution
INSERT OR IGNORE INTO pet_evolution_stages (species_id, stage_name, stage_level, required_owner_streak, required_owner_level, required_pet_happiness, appearance_description, stat_bonus_type, stat_bonus_value, unlock_message) VALUES
(4, 'Baby Dik-Dik', 1, 0, 1, 0, 'An impossibly tiny antelope with huge eyes', 'reminder', 1, 'A baby Dik-Dik bounces into your life!'),
(4, 'Swift Dik-Dik', 2, 14, 5, 40, 'Quick on its feet, always moving', 'social_xp_boost', 5, 'Swift Dik-Dik! +5% XP on exercise logging.'),
(4, 'Dik-Dik Scout', 3, 60, 12, 65, 'A sharp-eyed scout that spots health opportunities', 'rare_find', 5, 'Dik-Dik Scout! 5% chance to find rare crafting materials.'),
(4, 'Mythic Phantom Runner', 4, 180, 20, 85, 'A legendary speed spirit, nearly invisible when running', 'xp_boost', 12, 'MYTHIC! Phantom Runner! +12% XP + step tracking bonuses.');

-- Fish Eagle evolution
INSERT OR IGNORE INTO pet_evolution_stages (species_id, stage_name, stage_level, required_owner_streak, required_owner_level, required_pet_happiness, appearance_description, stat_bonus_type, stat_bonus_value, unlock_message) VALUES
(5, 'Eaglet', 1, 0, 1, 0, 'A downy eaglet learning to spread its wings', 'reminder', 1, 'A Fish Eaglet perches on your shoulder!'),
(5, 'Young Eagle', 2, 14, 5, 40, 'Developing flight feathers, starting to soar', 'rare_find', 3, 'Young Eagle soars! 3% chance to find rare items.'),
(5, 'Fish Eagle', 3, 60, 12, 65, 'A magnificent eagle scanning for the best opportunities', 'rare_find', 8, 'Majestic Fish Eagle! 8% rare item find chance.'),
(5, 'Mythic Thunderbird', 4, 180, 20, 85, 'A legendary storm eagle crackling with power', 'rare_find', 15, 'MYTHIC! Thunderbird! 15% rare finds + lightning XP bursts.');

-- Flamingo evolution
INSERT OR IGNORE INTO pet_evolution_stages (species_id, stage_name, stage_level, required_owner_streak, required_owner_level, required_pet_happiness, appearance_description, stat_bonus_type, stat_bonus_value, unlock_message) VALUES
(6, 'Flamingo Chick', 1, 0, 1, 0, 'A grey fluffy chick, not yet pink', 'reminder', 1, 'A grey Flamingo chick! Feed it well to turn it pink.'),
(6, 'Pink Flamingo', 2, 14, 5, 40, 'Starting to show pink - you must be staying hydrated!', 'reminder', 2, 'Getting pink! Your hydration is paying off.'),
(6, 'Scarlet Flamingo', 3, 60, 12, 65, 'Brilliant scarlet color, standing tall', 'xp_boost', 8, 'Scarlet Flamingo! +8% XP + hydration streak bonuses.'),
(6, 'Mythic Phoenix Flamingo', 4, 180, 20, 85, 'A flaming flamingo-phoenix hybrid, reborn from health', 'xp_boost', 15, 'MYTHIC! Phoenix Flamingo! +15% XP + streak protection.');

-- Silverback evolution
INSERT OR IGNORE INTO pet_evolution_stages (species_id, stage_name, stage_level, required_owner_streak, required_owner_level, required_pet_happiness, appearance_description, stat_bonus_type, stat_bonus_value, unlock_message) VALUES
(7, 'Baby Gorilla', 1, 0, 1, 0, 'A playful baby gorilla clinging to you', 'reminder', 1, 'A baby Gorilla has chosen you as family!'),
(7, 'Young Gorilla', 2, 21, 8, 45, 'Growing stronger each day, muscles developing', 'xp_boost', 5, 'Young Gorilla grows! +5% XP on exercise activities.'),
(7, 'Silverback', 3, 90, 15, 70, 'A powerful silverback with commanding presence', 'xp_boost', 10, 'Mighty Silverback! +10% XP on all physical activities.'),
(7, 'Mythic Mountain King', 4, 270, 25, 90, 'A legendary golden silverback, king of the mountain', 'xp_boost', 18, 'MYTHIC! Mountain King! +18% XP + strength avatar bonus.');

-- Honey Badger evolution
INSERT OR IGNORE INTO pet_evolution_stages (species_id, stage_name, stage_level, required_owner_streak, required_owner_level, required_pet_happiness, appearance_description, stat_bonus_type, stat_bonus_value, unlock_message) VALUES
(8, 'Badger Kit', 1, 0, 1, 0, 'A tiny but fierce badger kit', 'reminder', 1, 'A Honey Badger kit! Fierce and fearless.'),
(8, 'Young Badger', 2, 14, 5, 40, 'Already showing the fearless honey badger attitude', 'xp_boost', 5, 'Fearless Young Badger! +5% XP + streak protection.'),
(8, 'Honey Badger', 3, 60, 12, 65, 'The legendary honey badger - doesn''t care, never quits', 'xp_boost', 10, 'Honey Badger! +10% XP + forgives 1 missed day per week.'),
(8, 'Mythic Ironhide', 4, 180, 20, 85, 'An indestructible mythic badger wrapped in golden armor', 'xp_boost', 15, 'MYTHIC! Ironhide! +15% XP + forgives 2 missed days per week.');

-- ============================================================================
-- SEED: PET CARE ACTIONS
-- ============================================================================

INSERT OR IGNORE INTO pet_care_actions (action_name, action_type, trigger_event, happiness_change, health_change, hunger_change, xp_reward, description, cooldown_hours) VALUES
('Feed (Log Meal)', 'feed', 'meal_logged', 5, 2, 20, 5, 'Logging a meal feeds your pet', 0),
('Play (Exercise)', 'play', 'exercise_logged', 8, 3, -5, 5, 'Logging exercise plays with your pet', 4),
('Heal (Take Medication)', 'heal', 'med_taken', 3, 5, 0, 5, 'Taking medication heals your pet', 0),
('Hydrate (Log Water)', 'feed', 'hydration_logged', 3, 2, 10, 3, 'Logging water hydrates your pet', 2),
('Train (Complete Quest)', 'train', 'quest_completed', 10, 5, -10, 10, 'Completing a quest trains your pet', 0),
('Groom (Upload Lab Result)', 'groom', 'lab_uploaded', 5, 8, 0, 8, 'Uploading lab results grooms your pet', 24),
('Feast (Defeat Boss)', 'feed', 'boss_defeated', 15, 10, 30, 15, 'Defeating a boss throws a feast for your pet', 0),
('Socialize (Guild Activity)', 'play', 'guild_contributed', 8, 2, -3, 5, 'Guild activity socializes your pet', 8);

-- ============================================================================
-- SEED: PET ABILITIES
-- ============================================================================

-- Stage 1 (Baby) - all species get basic reminders
INSERT OR IGNORE INTO pet_abilities (species_id, stage_level, ability_name, ability_type, ability_value, description) VALUES
(1, 1, 'Gentle Hoot', 'reminder', 1, 'Owlet reminds you to log meals'),
(2, 1, 'Soft Nuzzle', 'reminder', 1, 'Bongo calf nudges you to check nutrients'),
(3, 1, 'Color Flash', 'reminder', 1, 'Chameleon flashes when glucose check is due'),
(4, 1, 'Tiny Tap', 'reminder', 1, 'Dik-Dik taps to encourage movement'),
(5, 1, 'Wing Flutter', 'reminder', 1, 'Eaglet flutters wings at meal time'),
(6, 1, 'Peep Peep', 'reminder', 1, 'Chick peeps for water breaks'),
(7, 1, 'Baby Hug', 'reminder', 1, 'Baby gorilla hugs to encourage exercise'),
(8, 1, 'Fearless Growl', 'reminder', 1, 'Badger kit growls at missed medications');

-- Stage 3 (Adult) - signature abilities
INSERT OR IGNORE INTO pet_abilities (species_id, stage_level, ability_name, ability_type, ability_value, description) VALUES
(1, 3, 'Wisdom Sight', 'passive_xp_boost', 7, '+7% passive XP boost on all actions'),
(2, 3, 'Kidney Guardian', 'nutrient_alert', 1, 'Alerts when K+ or P approaching limits'),
(3, 3, 'Prism Scan', 'nutrient_alert', 1, 'Visual glucose status + nutrient breakdown'),
(4, 3, 'Scout Sense', 'rare_find', 5, '5% chance to find rare crafting materials'),
(5, 3, 'Eagle Eye', 'rare_find', 8, '8% chance to find rare items after meals'),
(6, 3, 'Hydra Sense', 'reminder', 3, 'Advanced hydration tracking + reminders'),
(7, 3, 'Silver Strength', 'passive_xp_boost', 10, '+10% XP on exercise-related actions'),
(8, 3, 'Ironwill', 'med_reminder', 1, 'Persistent medication reminders + streak protection');

-- ============================================================================
-- SEED: PET DECAY RULES
-- ============================================================================

INSERT OR IGNORE INTO pet_decay_rules (decay_trigger, happiness_decay, health_decay, hunger_decay, decay_interval_hours, recovery_action, warning_message) VALUES
('no_meal_24h', -8, -3, -15, 24, 'meal_logged', 'Your pet is hungry! Log a meal to feed them.'),
('no_login_48h', -10, -5, -10, 48, 'daily_login', 'Your pet misses you! Log in to cheer them up.'),
('missed_medication', -5, -8, 0, 24, 'med_taken', 'Your pet feels unwell because you missed a medication.'),
('broken_streak', -15, -5, -5, 24, 'streak_restored', 'Your pet is sad your streak broke. Start a new one!'),
('no_exercise_72h', -5, -5, 0, 72, 'exercise_logged', 'Your pet needs to play! Log some exercise.'),
('no_hydration_24h', -5, -3, -8, 24, 'hydration_logged', 'Your pet is thirsty! Log your water intake.');

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT 'pet_species' AS tbl, COUNT(*) AS rows FROM pet_species
UNION ALL
SELECT 'pet_evolution_stages', COUNT(*) FROM pet_evolution_stages
UNION ALL
SELECT 'pet_care_actions', COUNT(*) FROM pet_care_actions
UNION ALL
SELECT 'pet_abilities', COUNT(*) FROM pet_abilities
UNION ALL
SELECT 'pet_decay_rules', COUNT(*) FROM pet_decay_rules
UNION ALL
SELECT 'user_pets', COUNT(*) FROM user_pets;
