-- Migration 076: Daily Login Rewards
-- 30-day rolling reward calendar
-- Free users: base rewards. Subscribers: 2x rewards + exclusive cosmetics

-- ============================================================================
-- DAILY LOGIN CALENDAR (30-day template)
-- ============================================================================

CREATE TABLE IF NOT EXISTS daily_login_calendar (
    id INTEGER PRIMARY KEY,
    day_number INTEGER NOT NULL UNIQUE,
        -- 1-30, rolls back to 1 after 30
    reward_type VARCHAR(40) NOT NULL,
        -- xp, afya_points, cosmetic, title, loot_box, crafting_material
    reward_value INTEGER NOT NULL,
        -- Amount of XP or AP, or item ID for cosmetic
    reward_description TEXT NOT NULL,
    subscriber_multiplier DOUBLE PRECISION DEFAULT 2.0,
        -- Plus/Pro get 2x the base reward
    subscriber_bonus_type VARCHAR(40),
        -- Extra reward type for subscribers
    subscriber_bonus_value INTEGER,
    subscriber_bonus_description TEXT,
    is_milestone_day BOOLEAN DEFAULT FALSE,
    icon VARCHAR(40),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- USER DAILY LOGINS
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_daily_logins (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    login_date DATE NOT NULL,
    day_in_cycle INTEGER NOT NULL,
        -- 1-30
    cycle_number INTEGER DEFAULT 1,
        -- How many times they've completed the 30-day cycle
    reward_claimed BOOLEAN DEFAULT FALSE,
    reward_type VARCHAR(40),
    reward_value INTEGER,
    bonus_claimed BOOLEAN DEFAULT FALSE,
    bonus_type VARCHAR(40),
    bonus_value INTEGER,
    streak_count INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, login_date)
);

-- ============================================================================
-- LOGIN STREAK MILESTONES
-- ============================================================================

CREATE TABLE IF NOT EXISTS login_streak_milestones (
    id INTEGER PRIMARY KEY,
    streak_days INTEGER NOT NULL UNIQUE,
    milestone_name VARCHAR(80) NOT NULL,
    reward_type VARCHAR(40) NOT NULL,
    reward_value INTEGER NOT NULL,
    subscriber_reward_type VARCHAR(40),
    subscriber_reward_value INTEGER,
    title_reward VARCHAR(80),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- SEED: 30-DAY LOGIN CALENDAR
-- ============================================================================

INSERT INTO daily_login_calendar (day_number, reward_type, reward_value, reward_description, subscriber_multiplier, subscriber_bonus_type, subscriber_bonus_value, subscriber_bonus_description, is_milestone_day, icon) VALUES
(1,  'xp', 10, '10 XP', 2.0, NULL, NULL, NULL, FALSE, 'star'),
(2,  'xp', 15, '15 XP', 2.0, NULL, NULL, NULL, FALSE, 'star'),
(3,  'afya_points', 5, '5 Afya Points', 2.0, NULL, NULL, NULL, FALSE, 'coin'),
(4,  'xp', 20, '20 XP', 2.0, NULL, NULL, NULL, FALSE, 'star'),
(5,  'xp', 20, '20 XP', 2.0, NULL, NULL, NULL, FALSE, 'star'),
(6,  'afya_points', 10, '10 Afya Points', 2.0, NULL, NULL, NULL, FALSE, 'coin'),
(7,  'xp', 50, '50 XP (Weekly Bonus!)', 2.0, 'cosmetic', 1, 'Exclusive weekly cosmetic', TRUE, 'trophy'),
(8,  'xp', 15, '15 XP', 2.0, NULL, NULL, NULL, FALSE, 'star'),
(9,  'afya_points', 10, '10 Afya Points', 2.0, NULL, NULL, NULL, FALSE, 'coin'),
(10, 'xp', 25, '25 XP', 2.0, NULL, NULL, NULL, FALSE, 'star'),
(11, 'xp', 20, '20 XP', 2.0, NULL, NULL, NULL, FALSE, 'star'),
(12, 'afya_points', 15, '15 Afya Points', 2.0, NULL, NULL, NULL, FALSE, 'coin'),
(13, 'xp', 25, '25 XP', 2.0, NULL, NULL, NULL, FALSE, 'star'),
(14, 'xp', 75, '75 XP (2-Week Bonus!)', 2.0, 'cosmetic', 2, 'Exclusive 2-week cosmetic', TRUE, 'trophy'),
(15, 'afya_points', 20, '20 Afya Points', 2.0, NULL, NULL, NULL, FALSE, 'coin'),
(16, 'xp', 25, '25 XP', 2.0, NULL, NULL, NULL, FALSE, 'star'),
(17, 'xp', 30, '30 XP', 2.0, NULL, NULL, NULL, FALSE, 'star'),
(18, 'afya_points', 20, '20 Afya Points', 2.0, NULL, NULL, NULL, FALSE, 'coin'),
(19, 'xp', 30, '30 XP', 2.0, NULL, NULL, NULL, FALSE, 'star'),
(20, 'xp', 35, '35 XP', 2.0, NULL, NULL, NULL, FALSE, 'star'),
(21, 'xp', 100, '100 XP (3-Week Bonus!)', 2.0, 'cosmetic', 3, 'Exclusive 3-week cosmetic', TRUE, 'trophy'),
(22, 'afya_points', 25, '25 Afya Points', 2.0, NULL, NULL, NULL, FALSE, 'coin'),
(23, 'xp', 35, '35 XP', 2.0, NULL, NULL, NULL, FALSE, 'star'),
(24, 'xp', 40, '40 XP', 2.0, NULL, NULL, NULL, FALSE, 'star'),
(25, 'afya_points', 30, '30 Afya Points', 2.0, NULL, NULL, NULL, FALSE, 'coin'),
(26, 'xp', 40, '40 XP', 2.0, NULL, NULL, NULL, FALSE, 'star'),
(27, 'xp', 45, '45 XP', 2.0, NULL, NULL, NULL, FALSE, 'star'),
(28, 'afya_points', 40, '40 Afya Points', 2.0, NULL, NULL, NULL, FALSE, 'coin'),
(29, 'xp', 50, '50 XP', 2.0, NULL, NULL, NULL, FALSE, 'star'),
(30, 'xp', 200, '200 XP + 100 AP (Monthly Bonus!)', 2.0, 'loot_box', 1, 'Exclusive Monthly Loot Box', TRUE, 'crown');

-- ============================================================================
-- SEED: STREAK MILESTONES
-- ============================================================================

INSERT INTO login_streak_milestones (streak_days, milestone_name, reward_type, reward_value, subscriber_reward_type, subscriber_reward_value, title_reward, description) VALUES
(7,   '7-Day Warrior',     'xp', 100,  'afya_points', 50,  'Dedicated',   'Logged in 7 days straight - you are building a healthy habit!'),
(14,  '14-Day Champion',   'xp', 250,  'afya_points', 100, 'Committed',   'Two weeks of consistency! Your avatar is growing stronger.'),
(21,  '21-Day Legend',     'xp', 500,  'afya_points', 200, 'Relentless',  'Three weeks! They say it takes 21 days to form a habit.'),
(30,  '30-Day Immortal',  'xp', 1000, 'afya_points', 500, 'Immortal',    'A full month of daily login! You are an Afya Immortal.'),
(60,  '60-Day Titan',     'xp', 2000, 'afya_points', 800, 'Titan',       'Two months! Your consistency is extraordinary.'),
(90,  '90-Day Phoenix',   'xp', 3000, 'afya_points', 1200, 'Phoenix',    'Three months! You have risen above. Health mastery is yours.'),
(180, '180-Day Ascended',  'xp', 5000, 'afya_points', 2000, 'Ascended',  'Six months of daily dedication. You are truly ascended.'),
(365, '365-Day Eternal',   'xp', 10000, 'afya_points', 5000, 'Eternal',  'One full year. You are Eternal. The ultimate health warrior.');

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT 'daily_login_calendar' AS tbl, COUNT(*) AS rows FROM daily_login_calendar
UNION ALL
SELECT 'user_daily_logins', COUNT(*) FROM user_daily_logins
UNION ALL
SELECT 'login_streak_milestones', COUNT(*) FROM login_streak_milestones;
