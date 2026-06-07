-- Migration 015: Create Leaderboard Views
-- Date: 2026-04-11
-- Purpose: Create SQL views for leaderboard calculations

-- 1. Weekly Meal Loggers Leaderboard
CREATE VIEW IF NOT EXISTS leaderboard_weekly_meal_loggers AS
SELECT
  'weekly_meal_loggers' AS leaderboard_name,
  u.id AS user_id,
  u.username,
  COUNT(DISTINCT DATE(m.created_at)) AS days_logged,
  COUNT(m.id) AS total_meals,
  RANK() OVER (ORDER BY COUNT(DISTINCT DATE(m.created_at)) DESC, COUNT(m.id) DESC) AS rank,
  DATE('now', 'weekday 0', '-7 days') AS period_start,
  DATE('now', 'weekday 6') AS period_end
FROM users u
LEFT JOIN meals m ON u.id = m.user_id
  AND m.created_at >= DATE('now', 'weekday 0', '-7 days')
  AND m.created_at < DATE('now', 'weekday 6')
GROUP BY u.id, u.username;

-- 2. Monthly Step Champions (uses wearable data or step_count_history)
CREATE VIEW IF NOT EXISTS leaderboard_monthly_step_champions AS
SELECT
  'monthly_step_champions' AS leaderboard_name,
  u.id AS user_id,
  u.username,
  COALESCE(SUM(CAST(json_extract(scl.data_json, '$.steps') AS INTEGER)), 0) AS total_steps,
  RANK() OVER (ORDER BY COALESCE(SUM(CAST(json_extract(scl.data_json, '$.steps') AS INTEGER)), 0) DESC) AS rank
FROM users u
LEFT JOIN (
  SELECT id AS user_id, '{"steps": 0}' AS data_json
  FROM users
  LIMIT 0
) scl ON u.id = scl.user_id
GROUP BY u.id, u.username;

-- 3. CKD Warriors (Best kidney_score improvement)
CREATE VIEW IF NOT EXISTS leaderboard_ckd_warriors AS
SELECT
  'ckd_warriors' AS leaderboard_name,
  u.id AS user_id,
  u.username,
  COALESCE(MAX(hs.kidney_score) - MIN(hs.kidney_score), 0) AS score_improvement,
  COALESCE(AVG(hs.kidney_score), 0) AS avg_score,
  RANK() OVER (ORDER BY COALESCE(MAX(hs.kidney_score) - MIN(hs.kidney_score), 0) DESC) AS rank
FROM users u
LEFT JOIN health_scores hs ON u.id = hs.user_id
  AND hs.date >= DATE('now', '-30 days')
GROUP BY u.id, u.username
HAVING COUNT(hs.id) >= 1;

-- 4. Medication Adherence Heroes
CREATE VIEW IF NOT EXISTS leaderboard_adherence_heroes AS
SELECT
  'adherence_heroes' AS leaderboard_name,
  u.id AS user_id,
  u.username,
  COALESCE(us.current_streak, 0) AS adherence_streak,
  RANK() OVER (ORDER BY COALESCE(us.current_streak, 0) DESC) AS rank
FROM users u
LEFT JOIN user_streaks us ON u.id = us.user_id
WHERE COALESCE(us.current_streak, 0) > 0
GROUP BY u.id, u.username, us.current_streak;

-- 5. Regional XP Leaderboard (by district/country)
CREATE VIEW IF NOT EXISTS leaderboard_regional_xp AS
SELECT
  COALESCE(up.district, 'Unknown') AS region,
  u.id AS user_id,
  u.username,
  COALESCE(av.current_xp + (av.level * 1000), 0) AS total_xp_estimate,
  av.level,
  RANK() OVER (PARTITION BY up.district ORDER BY COALESCE(av.current_xp + (av.level * 1000), 0) DESC) AS rank
FROM users u
LEFT JOIN user_Profiles up ON u.id = up.user_id
LEFT JOIN avatar_stats av ON u.id = av.user_id
WHERE up.district IS NOT NULL;

-- 6. Overall XP Leaderboard (all users)
CREATE VIEW IF NOT EXISTS leaderboard_overall_xp AS
SELECT
  'overall_xp' AS leaderboard_name,
  u.id AS user_id,
  u.username,
  COALESCE(av.level, 1) AS level,
  COALESCE(av.current_xp, 0) AS current_xp,
  COALESCE(av.current_xp + (av.level * 1000), 0) AS total_xp_estimate,
  RANK() OVER (ORDER BY COALESCE(av.current_xp + (av.level * 1000), 0) DESC) AS rank
FROM users u
LEFT JOIN avatar_stats av ON u.id = av.user_id;
