-- Migration 006: Seed Badges
-- Date: 2026-04-11
-- Purpose: Create 25+ badges across all rarity levels

-- Recreate badges table with proper schema
DROP TABLE IF EXISTS badges_old;
ALTER TABLE badges RENAME TO badges_old;

CREATE TABLE badges (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(80) NOT NULL,
  description TEXT,
  icon TEXT,
  requirement_description TEXT,
  badge_type VARCHAR(40),
  rarity VARCHAR(20),
  image_ref TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Migrate existing data (if any)
INSERT OR IGNORE INTO badges (id, name, description, icon, requirement_description)
SELECT id, name, description, icon, requirement_description
FROM badges_old
WHERE id IS NOT NULL;

DROP TABLE IF EXISTS badges_old;

-- COMMON BADGES (Starting achievements)
INSERT OR IGNORE INTO badges (name, badge_type, rarity, image_ref, description) VALUES
('First Steps', 'achievement', 'common', '/badges/first_steps.svg', 'First meal logged'),
('Hydration Start', 'achievement', 'common', '/badges/hydration_start.svg', 'First water log'),
('Med Beginner', 'achievement', 'common', '/badges/med_beginner.svg', 'First medication taken'),
('Lab Rookie', 'achievement', 'common', '/badges/lab_rookie.svg', 'First lab test');

-- UNCOMMON BADGES (Week-long achievements)
INSERT OR IGNORE INTO badges (name, badge_type, rarity, image_ref, description) VALUES
('Week Warrior', 'achievement', 'uncommon', '/badges/week_warrior.svg', '7-day logging streak'),
('Hydration Hero', 'achievement', 'uncommon', '/badges/hydration_hero.svg', '7-day hydration'),
('Social Starter', 'achievement', 'uncommon', '/badges/social_starter.svg', 'Joined first challenge'),
('Fitness Friend', 'achievement', 'uncommon', '/badges/fitness_friend.svg', '7-day activity tracking');

-- RARE BADGES (Month-long or clinical)
INSERT OR IGNORE INTO badges (name, badge_type, rarity, image_ref, description) VALUES
('Month Master', 'achievement', 'rare', '/badges/month_master.svg', '30-day consistency'),
('Med Guardian', 'achievement', 'rare', '/badges/med_guardian.svg', 'Perfect adherence week'),
('BP Tracker', 'achievement', 'rare', '/badges/bp_tracker.svg', 'Daily BP logging'),
('CKD Aware', 'achievement', 'rare', '/badges/ckd_aware.svg', 'CKD nutrition basics'),
('Diabetes Watch', 'achievement', 'rare', '/badges/diabetes_watch.svg', 'Glucose tracking');

-- EPIC BADGES (Major clinical achievements)
INSERT OR IGNORE INTO badges (name, badge_type, rarity, image_ref, description) VALUES
('Kidney Diet Master', 'achievement', 'epic', '/badges/kidney_master.svg', 'CKD diet mastery'),
('Perfect Adherence', 'achievement', 'epic', '/badges/perfect_adherence.svg', '30-day med streak'),
('Diabetes Control', 'achievement', 'epic', '/badges/diabetes_control.svg', 'Glucose mastery'),
('BP Champion', 'achievement', 'epic', '/badges/bp_champion.svg', 'Hypertension control'),
('eGFR Improver', 'achievement', 'epic', '/badges/egfr_improver.svg', 'Kidney function improved'),
('Level 20 Badge', 'achievement', 'epic', '/badges/level_20.svg', 'Reached level 20');

-- LEGENDARY BADGES (Ultimate achievements)
INSERT OR IGNORE INTO badges (name, badge_type, rarity, image_ref, description) VALUES
('Never Missed', 'achievement', 'legendary', '/badges/never_missed.svg', '90-day perfection'),
('Immortal', 'achievement', 'legendary', '/badges/immortal.svg', 'Level 50 reached'),
('CKD Guardian', 'achievement', 'legendary', '/badges/ckd_guardian.svg', 'CKD mastery'),
('Health Oracle', 'achievement', 'legendary', '/badges/health_oracle.svg', 'All skills unlocked');

-- SEASONAL BADGES
INSERT OR IGNORE INTO badges (name, badge_type, rarity, image_ref, description) VALUES
('Ramadan Wellness 2025', 'seasonal', 'epic', '/badges/ramadan_2025.svg', 'Ramadan event completion'),
('World Kidney Day 2025', 'seasonal', 'epic', '/badges/wkd_2025.svg', 'World Kidney Day participant'),
('Diabetes Awareness 2025', 'seasonal', 'rare', '/badges/diabetes_2025.svg', 'Diabetes Awareness Month');

-- CHALLENGE BADGES
INSERT OR IGNORE INTO badges (name, badge_type, rarity, image_ref, description) VALUES
('Team Champion', 'challenge', 'uncommon', '/badges/team_champ.svg', 'Won group challenge'),
('Solo Warrior', 'challenge', 'rare', '/badges/solo_warrior.svg', '10 solo challenges'),
('Friend Victor', 'challenge', 'uncommon', '/badges/friend_victor.svg', 'Won friend challenge');
