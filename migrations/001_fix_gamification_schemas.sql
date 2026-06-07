-- Migration 001: Fix Gamification Schema Issues
-- Date: 2026-04-11
-- Purpose: Fix broken foreign keys, wrong data types, and add missing columns

-- Fix 1: Add foreign key constraint to active_buffs
-- Issue: user_id references empty string instead of users table
DROP TABLE IF EXISTS active_buffs_old;
ALTER TABLE active_buffs RENAME TO active_buffs_old;

CREATE TABLE active_buffs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  buff_name VARCHAR(80) NOT NULL,
  buff_type VARCHAR(30),
  multiplier NUMERIC,
  expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Migrate existing data (if any)
INSERT OR IGNORE INTO active_buffs (user_id, buff_name, buff_type, multiplier, expires_at, created_at)
SELECT user_id, buff_name, buff_type, multiplier, expires_at, created_at
FROM active_buffs_old
WHERE user_id IS NOT NULL;

DROP TABLE IF EXISTS active_buffs_old;

-- Fix 2: Recreate game_sprites with correct data types
-- Issue: All columns are NUMERIC instead of proper types
DROP TABLE IF EXISTS game_sprites;

CREATE TABLE game_sprites (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  food_id INTEGER,
  sprite_path TEXT,
  buff_type VARCHAR(40),
  duration_hours REAL,
  collision_type VARCHAR(20),
  animation_state VARCHAR(30),
  aura_color_hex VARCHAR(7),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (food_id) REFERENCES foods(id) ON DELETE SET NULL
);

-- Fix 3: Add primary key to user_streaks and proper constraints
DROP TABLE IF EXISTS user_streaks_old;
ALTER TABLE user_streaks RENAME TO user_streaks_old;

CREATE TABLE user_streaks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL UNIQUE,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  last_logged_date DATE,
  last_action_date TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Migrate existing data
INSERT OR IGNORE INTO user_streaks (user_id, current_streak, longest_streak, last_logged_date, last_action_date)
SELECT user_id, current_streak, longest_streak, last_logged_date, last_action_date
FROM user_streaks_old
WHERE user_id IS NOT NULL;

DROP TABLE IF EXISTS user_streaks_old;

-- Fix 4: Add missing columns to avatar_stats
ALTER TABLE avatar_stats ADD COLUMN current_xp INTEGER DEFAULT 0;
ALTER TABLE avatar_stats ADD COLUMN level INTEGER DEFAULT 1;
ALTER TABLE avatar_stats ADD COLUMN class_id INTEGER;
ALTER TABLE avatar_stats ADD COLUMN xp_to_next_level INTEGER DEFAULT 100;
ALTER TABLE avatar_stats ADD COLUMN afya_points_balance INTEGER DEFAULT 0;
ALTER TABLE avatar_stats ADD COLUMN current_streak INTEGER DEFAULT 0;

-- Migrate data from user_stats to avatar_stats (if user_stats exists)
UPDATE avatar_stats
SET
  current_xp = COALESCE((SELECT XP_points FROM user_stats WHERE User_ID = avatar_stats.user_id), 0),
  level = COALESCE((SELECT Level FROM user_stats WHERE User_ID = avatar_stats.user_id), 1),
  current_streak = COALESCE((SELECT Current_Streak FROM user_stats WHERE User_ID = avatar_stats.user_id), 0)
WHERE EXISTS (SELECT 1 FROM user_stats WHERE User_ID = avatar_stats.user_id);

-- Archive user_stats (don't drop immediately - keep for rollback)
ALTER TABLE user_stats RENAME TO user_stats_archive;

-- Create indexes for performance
CREATE INDEX idx_avatar_stats_user ON avatar_stats(user_id);
CREATE INDEX idx_avatar_stats_level ON avatar_stats(level);
CREATE INDEX idx_user_achievements_user ON user_achievements(user_id);
CREATE INDEX idx_user_achievements_unlocked ON user_achievements(unlocked_at);
CREATE INDEX idx_leaderboards_competition ON leaderboards(competition_id, rank);
CREATE INDEX idx_active_buffs_expires ON active_buffs(user_id, expires_at);
CREATE INDEX idx_user_streaks_user ON user_streaks(user_id);
