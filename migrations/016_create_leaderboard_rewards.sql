-- Migration 016: Create Leaderboard Rewards
-- Date: 2026-04-11
-- Purpose: Define reward distribution for leaderboard rankings

CREATE TABLE leaderboard_rewards (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  leaderboard_name VARCHAR(80) NOT NULL,
  period VARCHAR(20), -- weekly / monthly / seasonal
  rank_min INTEGER NOT NULL,
  rank_max INTEGER NOT NULL,
  afya_points_reward INTEGER DEFAULT 0,
  badge_id INTEGER,
  cosmetic_id INTEGER,
  premium_days INTEGER DEFAULT 0, -- Days of Pro subscription
  description TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (badge_id) REFERENCES badges(id) ON DELETE SET NULL,
  FOREIGN KEY (cosmetic_id) REFERENCES avatar_cosmetics(id) ON DELETE SET NULL
);

-- WEEKLY REWARDS (Lower stakes, frequent)
INSERT OR IGNORE INTO leaderboard_rewards (leaderboard_name, period, rank_min, rank_max, afya_points_reward, description) VALUES
-- Weekly Meal Loggers
('weekly_meal_loggers', 'weekly', 1, 1, 500, '1st place - Weekly Meal Champion'),
('weekly_meal_loggers', 'weekly', 2, 3, 300, '2nd-3rd place'),
('weekly_meal_loggers', 'weekly', 4, 10, 150, '4th-10th place'),
('weekly_meal_loggers', 'weekly', 11, 25, 50, '11th-25th place'),

-- Weekly Adherence Heroes
('adherence_heroes', 'weekly', 1, 1, 600, '1st place - Perfect Adherence Champion'),
('adherence_heroes', 'weekly', 2, 3, 350, '2nd-3rd place'),
('adherence_heroes', 'weekly', 4, 10, 175, '4th-10th place');

-- MONTHLY REWARDS (Higher stakes, prestigious)
INSERT OR IGNORE INTO leaderboard_rewards (leaderboard_name, period, rank_min, rank_max, afya_points_reward, premium_days, description) VALUES
-- Monthly Step Champions
('monthly_step_champions', 'monthly', 1, 1, 2000, 30, '1st place + 1 month Pro'),
('monthly_step_champions', 'monthly', 2, 3, 1200, 0, '2nd-3rd place'),
('monthly_step_champions', 'monthly', 4, 10, 600, 0, '4th-10th place'),
('monthly_step_champions', 'monthly', 11, 50, 200, 0, '11th-50th place'),

-- Monthly CKD Warriors (CKD-FOCUSED, highest rewards)
('ckd_warriors', 'monthly', 1, 1, 2500, 30, '1st place - CKD Champion + 1 month Pro'),
('ckd_warriors', 'monthly', 2, 3, 1500, 0, '2nd-3rd place'),
('ckd_warriors', 'monthly', 4, 10, 800, 0, '4th-10th place'),
('ckd_warriors', 'monthly', 11, 30, 300, 0, '11th-30th place'),

-- Monthly Overall XP
('overall_xp', 'monthly', 1, 1, 3000, 30, '1st place - Health Legend + 1 month Pro'),
('overall_xp', 'monthly', 2, 3, 1800, 0, '2nd-3rd place'),
('overall_xp', 'monthly', 4, 10, 900, 0, '4th-10th place'),
('overall_xp', 'monthly', 11, 50, 300, 0, '11th-50th place');

CREATE INDEX idx_leaderboard_rewards_name ON leaderboard_rewards(leaderboard_name);
CREATE INDEX idx_leaderboard_rewards_period ON leaderboard_rewards(period);
CREATE INDEX idx_leaderboard_rewards_rank ON leaderboard_rewards(rank_min, rank_max);
