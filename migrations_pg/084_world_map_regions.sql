-- Migration 084: World Map / Health Regions
-- 10 regions representing health journey stages
-- Condition-aware: CKD patients unlock Renal Reef earlier, etc.
-- Free: 2 regions, Plus: 6, Pro: all 10

-- ============================================================================
-- WORLD MAP REGIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS world_map_regions (
    id INTEGER PRIMARY KEY,
    region_name VARCHAR(80) NOT NULL UNIQUE,
    region_subtitle VARCHAR(120),
    description TEXT NOT NULL,
    lore_text TEXT,
    theme VARCHAR(40) NOT NULL,
        -- tutorial, nutrition, hydration, exercise, medication, diagnostics,
        -- renal, cardiac, endocrine, mastery
    min_level INTEGER NOT NULL DEFAULT 1,
    max_level INTEGER NOT NULL DEFAULT 30,
    requires_subscription_tier INTEGER NOT NULL DEFAULT 1,
    condition_focus VARCHAR(60),
        -- NULL = general, CKD, Diabetes, Hypertension
    color_hex VARCHAR(10),
    icon VARCHAR(60),
    map_position_x DOUBLE PRECISION,
    map_position_y DOUBLE PRECISION,
    ambient_description TEXT,
    total_quests_available INTEGER DEFAULT 0,
    total_bosses_available INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- REGION UNLOCK REQUIREMENTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS region_unlock_requirements (
    id INTEGER PRIMARY KEY,
    region_id INTEGER NOT NULL REFERENCES world_map_regions(id),
    requirement_type VARCHAR(40) NOT NULL,
        -- level, achievement, quest_complete, condition, subscription,
        -- boss_defeated, streak
    requirement_key VARCHAR(80) NOT NULL,
    requirement_value DOUBLE PRECISION,
    requirement_text TEXT NOT NULL,
    is_mandatory BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- REGION CONTENT (quests, bosses, NPCs per region)
-- ============================================================================

CREATE TABLE IF NOT EXISTS region_content (
    id INTEGER PRIMARY KEY,
    region_id INTEGER NOT NULL REFERENCES world_map_regions(id),
    content_type VARCHAR(40) NOT NULL,
        -- quest, boss, npc, crafting_station, guild_hall, shop, landmark
    content_id INTEGER,
        -- FK to quest/boss/etc. depending on type
    content_name VARCHAR(120) NOT NULL,
    description TEXT,
    unlock_at_exploration_pct DOUBLE PRECISION DEFAULT 0,
        -- What % of region must be explored to access this
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- USER REGION PROGRESS
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_region_progress (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    region_id INTEGER NOT NULL REFERENCES world_map_regions(id),
    status VARCHAR(20) NOT NULL DEFAULT 'locked',
        -- locked, unlocked, exploring, completed, mastered
    exploration_pct DOUBLE PRECISION DEFAULT 0,
        -- 0-100%
    quests_completed INTEGER DEFAULT 0,
    bosses_defeated INTEGER DEFAULT 0,
    discoveries_made INTEGER DEFAULT 0,
    time_spent_hours DOUBLE PRECISION DEFAULT 0,
    first_entered_at TIMESTAMP,
    completed_at TIMESTAMP,
    mastered_at TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, region_id)
);

-- ============================================================================
-- SEED: 10 WORLD MAP REGIONS
-- ============================================================================

INSERT INTO world_map_regions (id, region_name, region_subtitle, description, lore_text, theme, min_level, max_level, requires_subscription_tier, condition_focus, color_hex, icon, map_position_x, map_position_y, ambient_description, total_quests_available, total_bosses_available) VALUES
(1, 'Wellness Meadows', 'Where Every Journey Begins',
 'A peaceful grassland where new health warriors learn the basics. Log meals, set goals, and discover your path.',
 'In the gentle meadows of Wellness, every Vurafya warrior takes their first steps. The grass is green, the air is fresh, and the path ahead stretches to the horizon.',
 'tutorial', 1, 5, 1, NULL, '#86EFAC', 'meadow', 10, 80, 'Gentle breeze, chirping birds, morning dew on grass', 8, 1),

(2, 'Nutrition Valley', 'The Garden of Knowledge',
 'A lush valley filled with food wisdom. Master meal logging, learn about macros, and craft your first potions.',
 'Nutrition Valley teems with knowledge. Ancient food scrolls line the paths, and the great chefs of Africa have left their recipes carved in stone.',
 'nutrition', 3, 8, 1, NULL, '#4ADE80', 'valley', 25, 70, 'Aromatic herbs, bubbling cooking pots, market sounds', 10, 1),

(3, 'Hydration Springs', 'The Crystal Waters',
 'Sparkling springs and waterfalls where hydration mastery is tested. Track your water, understand fluid balance.',
 'The Hydration Springs flow from the mountains of discipline. Those who drink deeply find clarity and strength.',
 'hydration', 5, 12, 2, NULL, '#38BDF8', 'springs', 40, 60, 'Flowing water, splashing falls, cool mist', 6, 1),

(4, 'Vitality Forest', 'The Living Woods',
 'A dense forest where exercise and movement are the way forward. Walk, run, and move to carve your path.',
 'The Vitality Forest is alive - every step you take makes the trees glow brighter. Sedentary souls find the forest dark and impassable.',
 'exercise', 8, 15, 2, NULL, '#22C55E', 'forest', 55, 50, 'Rustling leaves, animal calls, dappled sunlight', 8, 2),

(5, 'Medicine Mountain', 'The Peak of Adherence',
 'A towering mountain where medication adherence is tested. The Medication Skip Demon lurks in the caves.',
 'Medicine Mountain was built by the forgotten pills and skipped doses of millions. Only the adherent can reach its summit.',
 'medication', 10, 20, 2, NULL, '#A78BFA', 'mountain', 65, 35, 'Mountain winds, echoing caves, distant thunder', 7, 2),

(6, 'Lab Caverns', 'The Halls of Discovery',
 'Underground caverns lit by bioluminescent crystals. Each crystal represents a lab result. Track your biomarkers here.',
 'Deep beneath the surface, the Lab Caverns hold the truth about your body. Every test result illuminates another crystal.',
 'diagnostics', 12, 22, 2, NULL, '#818CF8', 'cavern', 50, 25, 'Dripping water, glowing crystals, echoes', 6, 1),

(7, 'Renal Reef', 'The Kidney Kingdom',
 'An underwater realm for kidney warriors. PRAL tracking, 3P management, and the mighty CKD bosses await.',
 'Beneath the waves of Renal Reef, the Phosphorus Phantom and Potassium Kraken guard the secrets of kidney health. Only those who master their electrolytes can breathe here.',
 'renal', 15, 25, 2, 'CKD', '#06B6D4', 'reef', 35, 15, 'Bubbling water, whale songs, coral chimes', 10, 3),

(8, 'Cardio Citadel', 'The Heart Fortress',
 'A grand citadel where cardiovascular health is the key. BP control, cholesterol management, and heart-healthy living.',
 'The Cardio Citadel stands strong when blood flows clean and steady. The BP Storm Giant rattles its walls when pressure rises.',
 'cardiac', 18, 28, 2, 'Hypertension', '#F43F5E', 'citadel', 70, 20, 'Steady heartbeat rhythm, marching drums, trumpet calls', 8, 2),

(9, 'Endocrine Empire', 'The Metabolic Realm',
 'A vast empire of hormonal balance. Glucose control, insulin management, and the Sugar Dragon await.',
 'The Endocrine Empire rises and falls with blood sugar. The Sugar Dragon rules from its throne of excess, but disciplined warriors bring balance.',
 'endocrine', 20, 30, 3, 'Diabetes', '#F59E0B', 'empire', 80, 30, 'Warm desert winds, ancient machinery, energy hums', 8, 2),

(10, 'Champion Summit', 'The Pinnacle of Health',
 'The highest peak in the Vurafya world. Only those who have mastered all aspects of health can reach the summit. Endgame content.',
 'At the Champion Summit, the greatest health warriors gather. Here, all conditions are mastered, all bosses defeated, and the view encompasses the entire world of health.',
 'mastery', 25, 99, 3, NULL, '#EAB308', 'summit', 90, 10, 'Ethereal music, golden light, peaceful silence', 5, 2);

-- ============================================================================
-- SEED: REGION UNLOCK REQUIREMENTS
-- ============================================================================

-- Region 1: Wellness Meadows (free, always unlocked)
INSERT INTO region_unlock_requirements (region_id, requirement_type, requirement_key, requirement_value, requirement_text) VALUES
(1, 'level', 'min_level', 1, 'Available to all new warriors');

-- Region 2: Nutrition Valley
INSERT INTO region_unlock_requirements (region_id, requirement_type, requirement_key, requirement_value, requirement_text) VALUES
(2, 'level', 'min_level', 3, 'Reach level 3'),
(2, 'quest_complete', 'the_journey_begins', 1, 'Complete "The Journey Begins" quest');

-- Region 3: Hydration Springs
INSERT INTO region_unlock_requirements (region_id, requirement_type, requirement_key, requirement_value, requirement_text) VALUES
(3, 'level', 'min_level', 5, 'Reach level 5'),
(3, 'subscription', 'min_tier', 2, 'Afya Plus or Pro subscription required');

-- Region 4: Vitality Forest
INSERT INTO region_unlock_requirements (region_id, requirement_type, requirement_key, requirement_value, requirement_text) VALUES
(4, 'level', 'min_level', 8, 'Reach level 8'),
(4, 'subscription', 'min_tier', 2, 'Afya Plus or Pro subscription required'),
(4, 'streak', 'min_streak', 7, 'Maintain 7-day logging streak');

-- Region 5: Medicine Mountain
INSERT INTO region_unlock_requirements (region_id, requirement_type, requirement_key, requirement_value, requirement_text) VALUES
(5, 'level', 'min_level', 10, 'Reach level 10'),
(5, 'subscription', 'min_tier', 2, 'Afya Plus or Pro subscription required'),
(5, 'achievement', 'med_adherence_week', 1, 'Earn Med Adherence Week achievement');

-- Region 6: Lab Caverns
INSERT INTO region_unlock_requirements (region_id, requirement_type, requirement_key, requirement_value, requirement_text) VALUES
(6, 'level', 'min_level', 12, 'Reach level 12'),
(6, 'subscription', 'min_tier', 2, 'Afya Plus or Pro subscription required'),
(6, 'achievement', 'first_lab_test', 1, 'Complete First Lab Test achievement');

-- Region 7: Renal Reef (CKD patients unlock earlier at level 8)
INSERT INTO region_unlock_requirements (region_id, requirement_type, requirement_key, requirement_value, requirement_text, is_mandatory) VALUES
(7, 'level', 'min_level', 15, 'Reach level 15 (or level 8 with CKD condition)', TRUE),
(7, 'subscription', 'min_tier', 2, 'Afya Plus or Pro subscription required', TRUE),
(7, 'condition', 'ckd_early_access', 8, 'CKD patients: level 8 unlocks early access', FALSE);

-- Region 8: Cardio Citadel
INSERT INTO region_unlock_requirements (region_id, requirement_type, requirement_key, requirement_value, requirement_text, is_mandatory) VALUES
(8, 'level', 'min_level', 18, 'Reach level 18 (or level 10 with HTN condition)', TRUE),
(8, 'subscription', 'min_tier', 2, 'Afya Plus or Pro subscription required', TRUE),
(8, 'condition', 'htn_early_access', 10, 'Hypertension patients: level 10 unlocks early access', FALSE);

-- Region 9: Endocrine Empire (Diabetes patients unlock earlier)
INSERT INTO region_unlock_requirements (region_id, requirement_type, requirement_key, requirement_value, requirement_text, is_mandatory) VALUES
(9, 'level', 'min_level', 20, 'Reach level 20 (or level 12 with Diabetes condition)', TRUE),
(9, 'subscription', 'min_tier', 3, 'Afya Pro subscription required', TRUE),
(9, 'condition', 'diabetes_early_access', 12, 'Diabetes patients: level 12 unlocks early access', FALSE);

-- Region 10: Champion Summit
INSERT INTO region_unlock_requirements (region_id, requirement_type, requirement_key, requirement_value, requirement_text) VALUES
(10, 'level', 'min_level', 25, 'Reach level 25'),
(10, 'subscription', 'min_tier', 3, 'Afya Pro subscription required'),
(10, 'boss_defeated', 'any_boss', 3, 'Defeat at least 3 different bosses'),
(10, 'achievement', 'gold_tier_count', 5, 'Earn 5 Gold-tier achievements');

-- ============================================================================
-- SEED: REGION CONTENT
-- ============================================================================

INSERT INTO region_content (region_id, content_type, content_id, content_name, description, unlock_at_exploration_pct) VALUES
-- Wellness Meadows content
(1, 'quest', 31, 'The Journey Begins', 'Starting story quest', 0),
(1, 'quest', 6, 'Perfect Day Challenge', 'Daily challenge', 10),
(1, 'quest', 5, '3-Day Water Sprint', 'Hydration introduction', 20),
(1, 'boss', 12, 'Sedentary Shadow', 'First boss encounter', 50),
(1, 'crafting_station', NULL, 'Beginner Cauldron', 'Craft basic potions', 30),
(1, 'landmark', NULL, 'Health Declaration Shrine', 'Declare your health conditions here', 0),

-- Nutrition Valley content
(2, 'quest', 17, 'Protein Power Week', 'Weekly protein quest', 0),
(2, 'quest', 33, 'Clinical Excellence', 'Story quest', 20),
(2, 'boss', 11, 'Calorie Overlord', 'Nutrition boss', 40),
(2, 'crafting_station', NULL, 'Kitchen Workshop', 'Craft nutrition potions', 15),
(2, 'shop', NULL, 'Nutrition Market', 'Buy meal plan items', 25),

-- Hydration Springs content
(3, 'quest', 19, 'Hydration Champion Week', 'Weekly hydration quest', 0),
(3, 'boss', 13, 'Dehydration Wraith', 'Hydration boss', 30),
(3, 'crafting_station', NULL, 'Spring Fountain', 'Craft hydration tonics', 20),

-- Vitality Forest content
(4, 'quest', 18, 'Step God Challenge', 'Weekly step quest', 0),
(4, 'quest', 26, '30-Day Transformation', 'Monthly challenge', 25),
(4, 'boss', 12, 'Sedentary Shadow (Hard)', 'Harder version', 50),

-- Medicine Mountain content
(5, 'quest', 7, 'Med Adherence Day', 'Daily medication quest', 0),
(5, 'quest', 27, 'Med Champion Month', 'Monthly med quest', 20),
(5, 'boss', 15, 'Medication Skip Demon', 'Medication boss', 40),

-- Lab Caverns content
(6, 'quest', 33, 'Clinical Excellence', 'Lab-focused story quest', 0),
(6, 'landmark', NULL, 'Crystal of Results', 'View lab history visualization', 15),

-- Renal Reef content
(7, 'quest', 1, 'Kidney-Safe Day', 'Daily CKD quest', 0),
(7, 'quest', 8, 'Kidney Safe Week', 'Weekly CKD quest', 10),
(7, 'quest', 32, 'Mastering CKD Nutrition', 'CKD story quest', 5),
(7, 'quest', 20, 'CKD Diet Champion Month', 'Monthly CKD quest', 20),
(7, 'boss', 1, 'Phosphorus Phantom', 'CKD boss', 30),
(7, 'boss', 2, 'Potassium Kraken', 'CKD boss', 50),
(7, 'boss', 3, 'Uremia Dragon', 'CKD final boss', 75),
(7, 'crafting_station', NULL, 'Alkaline Forge', 'Craft CKD-specific potions', 15),

-- Cardio Citadel content
(8, 'quest', 15, 'BP Perfect Week', 'HTN quest', 0),
(8, 'quest', 16, 'DASH Diet Week', 'DASH diet quest', 15),
(8, 'boss', 7, 'BP Storm Giant', 'HTN boss', 30),
(8, 'boss', 8, 'Salt Golem', 'Sodium boss', 45),
(8, 'boss', 9, 'Cholesterol Hydra', 'Cholesterol boss', 60),

-- Endocrine Empire content
(9, 'quest', 13, 'Glucose Control Week', 'Diabetes quest', 0),
(9, 'quest', 14, 'Low GI Week', 'GI quest', 15),
(9, 'quest', 24, 'Glucose Control Master', 'Monthly diabetes quest', 25),
(9, 'boss', 5, 'Sugar Dragon', 'Diabetes boss', 35),
(9, 'boss', 6, 'Insulin Resistance Golem', 'Diabetes boss', 55),

-- Champion Summit content
(10, 'landmark', NULL, 'Hall of Champions', 'View global leaderboard', 0),
(10, 'landmark', NULL, 'Trophy Room', 'View all achievements', 10),
(10, 'quest', NULL, 'The Final Challenge', 'Ultimate mastery quest (coming soon)', 50),
(10, 'boss', NULL, 'The Health Sentinel', 'Ultimate boss (coming soon)', 75),
(10, 'guild_hall', NULL, 'Champion Guild Hall', 'Premium guild meeting space', 25);

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT 'world_map_regions' AS tbl, COUNT(*) AS rows FROM world_map_regions
UNION ALL
SELECT 'region_unlock_requirements', COUNT(*) FROM region_unlock_requirements
UNION ALL
SELECT 'region_content', COUNT(*) FROM region_content
UNION ALL
SELECT 'user_region_progress', COUNT(*) FROM user_region_progress;
