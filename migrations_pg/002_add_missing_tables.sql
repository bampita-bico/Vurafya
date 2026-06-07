-- Migration 002: Add Missing Gamification Tables
-- Date: 2026-04-11
-- Purpose: Create 10 missing tables from PDF specification (Module 11)

-- 1. Character Classes System
CREATE TABLE game_character_classes (
  id SERIAL PRIMARY KEY,
  class_name VARCHAR(60) NOT NULL UNIQUE,
  focus_area VARCHAR(60), -- CKD Nutrition / Fitness / Mental Health / Clinical / Prevention
  xp_multiplier DOUBLE PRECISION DEFAULT 1.0,
  base_hp INTEGER DEFAULT 100,
  starting_skills TEXT, -- JSON array of skill_tree IDs
  description TEXT,
  icon_ref TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Character Progression Curve
CREATE TABLE character_progression (
  id SERIAL PRIMARY KEY,
  class_id INTEGER NOT NULL,
  level INTEGER NOT NULL,
  xp_required INTEGER NOT NULL,
  title_unlocked VARCHAR(80),
  reward_item_id INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (class_id) REFERENCES game_character_classes(id) ON DELETE CASCADE,
  UNIQUE (class_id, level)
);

-- 3. Game Quests (not in current schema)
CREATE TABLE game_quests (
  id SERIAL PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  quest_type VARCHAR(40), -- daily / weekly / monthly / seasonal / story
  description TEXT,
  xp_reward INTEGER DEFAULT 0,
  points_reward INTEGER DEFAULT 0,
  duration_days INTEGER,
  condition_focus VARCHAR(60), -- CKD / Diabetes / HTN / General
  min_level_required INTEGER DEFAULT 1,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Quest Objectives (sub-tasks)
CREATE TABLE quest_objectives (
  id SERIAL PRIMARY KEY,
  quest_id INTEGER NOT NULL,
  description TEXT,
  objective_type VARCHAR(40), -- log_meal / hit_water_target / step_count / lab_done / meditation
  target_value DOUBLE PRECISION,
  sequence_order INTEGER DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (quest_id) REFERENCES game_quests(id) ON DELETE CASCADE
);

-- 5. User Quest Progress Tracking
CREATE TABLE user_quest_progress (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  quest_id INTEGER NOT NULL,
  objective_id INTEGER NOT NULL,
  current_value DOUBLE PRECISION DEFAULT 0,
  is_completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMP,
  started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (quest_id) REFERENCES game_quests(id) ON DELETE CASCADE,
  FOREIGN KEY (objective_id) REFERENCES quest_objectives(id) ON DELETE CASCADE,
  UNIQUE (user_id, objective_id)
);

-- 6. Skill Tree (Health Knowledge Nodes)
CREATE TABLE skill_tree (
  id SERIAL PRIMARY KEY,
  skill_name VARCHAR(80) NOT NULL UNIQUE,
  category VARCHAR(40), -- Nutrition / Fitness / Pharmacology / Mental Health / Clinical
  prerequisite_id INTEGER,
  xp_cost INTEGER DEFAULT 0,
  description TEXT,
  is_premium BOOLEAN DEFAULT FALSE,
  icon_ref TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (prerequisite_id) REFERENCES skill_tree(id) ON DELETE SET NULL
);

-- 7. User Skills Unlocked
CREATE TABLE user_skills (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  skill_id INTEGER NOT NULL,
  unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (skill_id) REFERENCES skill_tree(id) ON DELETE CASCADE,
  UNIQUE (user_id, skill_id)
);

-- 8. Avatar Cosmetics Catalog
CREATE TABLE avatar_cosmetics (
  id SERIAL PRIMARY KEY,
  cosmetic_name VARCHAR(80) NOT NULL,
  cosmetic_type VARCHAR(40), -- hat / outfit / badge_frame / background / effect
  rarity VARCHAR(20), -- common / uncommon / rare / epic / legendary
  unlock_method VARCHAR(40), -- quest / achievement / purchase / seasonal
  cost_afya_points INTEGER DEFAULT 0,
  image_ref TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 9. User Cosmetics Inventory
CREATE TABLE user_cosmetics (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  cosmetic_id INTEGER NOT NULL,
  is_equipped BOOLEAN DEFAULT FALSE,
  acquired_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (cosmetic_id) REFERENCES avatar_cosmetics(id) ON DELETE CASCADE,
  UNIQUE (user_id, cosmetic_id)
);

-- 10. Seasonal Events
CREATE TABLE season_pass_metadata (
  id SERIAL PRIMARY KEY,
  season_name VARCHAR(80) NOT NULL,
  theme TEXT,
  starts_at DATE NOT NULL,
  ends_at DATE NOT NULL,
  exclusive_quests TEXT, -- JSON array of quest IDs
  exclusive_rewards TEXT, -- JSON array of cosmetic IDs
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 11. Reward Redemption Ledger
CREATE TABLE reward_redemption_log (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  points_spent INTEGER NOT NULL,
  reward_type VARCHAR(60), -- pharmacy_discount / lab_test_voucher / consultation_credit / cosmetic
  reward_description TEXT,
  reward_value_ugx DOUBLE PRECISION,
  facility_id INTEGER,
  redeemed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  status VARCHAR(20) DEFAULT 'processed', -- processed / pending / expired
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (facility_id) REFERENCES partner_facilities(id) ON DELETE SET NULL
);

-- Add foreign key constraint to avatar_stats (class_id → game_character_classes)
-- Note: SQLite doesn't support ALTER TABLE ADD CONSTRAINT, so we document it here
-- This will be enforced in application logic and future PostgreSQL migration

-- Create performance indexes
CREATE INDEX idx_character_progression_class_level ON character_progression(class_id, level);
CREATE INDEX idx_quest_objectives_quest ON quest_objectives(quest_id);
CREATE INDEX idx_user_quest_progress_user ON user_quest_progress(user_id);
CREATE INDEX idx_user_quest_progress_quest ON user_quest_progress(quest_id);
CREATE INDEX idx_user_skills_user ON user_skills(user_id);
CREATE INDEX idx_user_cosmetics_user ON user_cosmetics(user_id);
CREATE INDEX idx_user_cosmetics_equipped ON user_cosmetics(user_id, is_equipped);
CREATE INDEX idx_reward_redemption_user ON reward_redemption_log(user_id);
CREATE INDEX idx_reward_redemption_date ON reward_redemption_log(redeemed_at);
