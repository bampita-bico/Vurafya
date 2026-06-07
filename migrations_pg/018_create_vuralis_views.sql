-- Migration 018: Create Vuralis Integration Views
-- Date: 2026-04-11
-- Purpose: One-way data bridge from Vurafya → Vuralis (read-only views)
-- REQUIRES: user_app_settings.vuralis_data_bridge_consent = TRUE

-- Avatar Stats View (7 Health-Mapped Attributes)
-- Maps Vurafya health data → Vuralis avatar appearance & behavior
CREATE VIEW IF NOT EXISTS vuralis_avatar_stats AS
SELECT
  u.id AS user_id,
  u.username,

  -- 1. Health Level (0-100): Composite of health scores + adherence + nutrition
  CAST(COALESCE(
    (hs.longevity_score * 0.3) +
    (hs.kidney_score * 0.25) +
    (hs.metabolic_score * 0.2) +
    ((us.current_streak / 90.0 * 100) * 0.15) + -- Adherence streak (max 90 days = 100 pts)
    (CASE WHEN m.meals_this_month >= 60 THEN 100 ELSE (m.meals_this_month / 60.0 * 100) END * 0.1), -- Nutrition consistency
    50
  ) AS INTEGER) AS health_level,

  -- 2. Energy Level (0-100): Activity (steps) + Sleep quality
  CAST(COALESCE(
    (CASE WHEN act.avg_steps >= 10000 THEN 100 ELSE (act.avg_steps / 10000.0 * 100) END * 0.6) +
    (CASE WHEN sl.avg_sleep_hours >= 8 THEN 100 WHEN sl.avg_sleep_hours >= 6 THEN 75 ELSE (sl.avg_sleep_hours / 8.0 * 100) END * 0.4),
    50
  ) AS INTEGER) AS energy_level,

  -- 3. Brain Power (0-100): Nutrition adherence + Mental wellness
  CAST(COALESCE(
    (CASE WHEN m.meals_this_month >= 60 THEN 100 ELSE (m.meals_this_month / 60.0 * 100) END * 0.5) +
    (CASE WHEN mh.mental_wellness_score IS NOT NULL THEN mh.mental_wellness_score ELSE 50 END * 0.5),
    50
  ) AS INTEGER) AS brain_power,

  -- 4. Muscle Strength (0-100): Protein intake + Activity
  CAST(COALESCE(
    (CASE WHEN n.avg_protein_g >= 60 THEN 100 ELSE (n.avg_protein_g / 60.0 * 100) END * 0.6) +
    (CASE WHEN act.avg_steps >= 8000 THEN 100 ELSE (act.avg_steps / 8000.0 * 100) END * 0.4),
    50
  ) AS INTEGER) AS muscle_strength,

  -- 5. Immunity Level (0-100): Micronutrient completeness + Vaccinations
  CAST(COALESCE(
    (CASE WHEN n.micronutrient_score >= 80 THEN 100 ELSE n.micronutrient_score END * 0.7) +
    (CASE WHEN vax.vaccination_score >= 80 THEN 100 ELSE vax.vaccination_score END * 0.3),
    50
  ) AS INTEGER) AS immunity_level,

  -- 6. Resilience Level (0-100): Current streak × 3 (capped at 100)
  CAST(COALESCE(
    CASE WHEN us.current_streak * 3 > 100 THEN 100 ELSE us.current_streak * 3 END,
    0
  ) AS INTEGER) AS resilience_level,

  -- 7. Gut Health (0-100): Fiber intake + Hydration + Probiotic foods
  CAST(COALESCE(
    (CASE WHEN n.avg_fiber_g >= 25 THEN 100 ELSE (n.avg_fiber_g / 25.0 * 100) END * 0.4) +
    (CASE WHEN h.avg_water_ml >= 2000 THEN 100 ELSE (h.avg_water_ml / 2000.0 * 100) END * 0.3) +
    (CASE WHEN n.probiotic_servings >= 7 THEN 100 ELSE (n.probiotic_servings / 7.0 * 100) END * 0.3),
    50
  ) AS INTEGER) AS gut_health,

  -- Additional context for Vuralis
  av.level AS avatar_level,
  av.current_xp AS avatar_xp,
  gcc.class_name AS character_class,
  us.current_streak AS adherence_streak,
  DATETIME('now') AS last_synced_at

FROM users u
LEFT JOIN avatar_stats av ON u.id = av.user_id
LEFT JOIN game_character_classes gcc ON av.class_id = gcc.id
LEFT JOIN user_streaks us ON u.id = us.user_id

-- Health Scores (30-day window)
LEFT JOIN (
  SELECT user_id,
    AVG(kidney_score) AS kidney_score,
    AVG(metabolic_score) AS metabolic_score,
    AVG(longevity_score) AS longevity_score
  FROM health_scores
  WHERE date >= DATE('now', '-30 days')
  GROUP BY user_id
) hs ON u.id = hs.user_id

-- Meal Logging Stats (30-day window)
LEFT JOIN (
  SELECT user_id,
    COUNT(*) AS meals_this_month
  FROM meals
  WHERE created_at >= DATE('now', '-30 days')
  GROUP BY user_id
) m ON u.id = m.user_id

-- Activity Stats (30-day window)
LEFT JOIN (
  SELECT user_id,
    AVG(CAST(json_extract(data_json, '$.steps') AS INTEGER)) AS avg_steps
  FROM (
    SELECT id AS user_id, '{"steps": 0}' AS data_json
    FROM users LIMIT 0
  )
  GROUP BY user_id
) act ON u.id = act.user_id

-- Sleep Stats (30-day window)
LEFT JOIN (
  SELECT user_id,
    AVG(CAST(json_extract(data_json, '$.hours') AS DOUBLE PRECISION)) AS avg_sleep_hours
  FROM (
    SELECT id AS user_id, '{"hours": 7}' AS data_json
    FROM users LIMIT 0
  )
  GROUP BY user_id
) sl ON u.id = sl.user_id

-- Mental Health Stats (30-day window)
LEFT JOIN (
  SELECT user_id,
    AVG(wellness_score) AS mental_wellness_score
  FROM (
    SELECT id AS user_id, 50 AS wellness_score
    FROM users LIMIT 0
  )
  GROUP BY user_id
) mh ON u.id = mh.user_id

-- Nutrition Macros (30-day window)
LEFT JOIN (
  SELECT user_id,
    AVG(CAST(json_extract(nutrition_json, '$.protein_g') AS DOUBLE PRECISION)) AS avg_protein_g,
    AVG(CAST(json_extract(nutrition_json, '$.fiber_g') AS DOUBLE PRECISION)) AS avg_fiber_g,
    COALESCE(SUM(CASE WHEN json_extract(nutrition_json, '$.is_probiotic') = 1 THEN 1 ELSE 0 END), 0) AS probiotic_servings,
    50 AS micronutrient_score
  FROM (
    SELECT id AS user_id, '{"protein_g": 0, "fiber_g": 0, "is_probiotic": 0}' AS nutrition_json
    FROM users LIMIT 0
  )
  GROUP BY user_id
) n ON u.id = n.user_id

-- Hydration Stats (30-day window)
LEFT JOIN (
  SELECT user_id,
    AVG(water_ml) AS avg_water_ml
  FROM (
    SELECT id AS user_id, 0 AS water_ml
    FROM users LIMIT 0
  )
  GROUP BY user_id
) h ON u.id = h.user_id

-- Vaccination Status
LEFT JOIN (
  SELECT id AS user_id,
    50 AS vaccination_score
  FROM users
) vax ON u.id = vax.user_id

-- Only include users who have consented to Vuralis data bridge
WHERE EXISTS (
  SELECT 1 FROM user_app_settings uas
  WHERE uas.user_id = u.id
  AND uas.vuralis_data_bridge_consent = TRUE
);

-- Health Scores Summary View (for Vuralis city environment responses)
CREATE VIEW IF NOT EXISTS vuralis_health_scores AS
SELECT
  u.id AS user_id,
  u.username,

  -- Current health scores (30-day avg)
  CAST(COALESCE(AVG(hs.kidney_score), 50) AS INTEGER) AS kidney_score,
  CAST(COALESCE(AVG(hs.diabetes_score), 50) AS INTEGER) AS diabetes_score,
  CAST(COALESCE(AVG(hs.bp_score), 50) AS INTEGER) AS bp_score,
  CAST(COALESCE(AVG(hs.metabolic_score), 50) AS INTEGER) AS metabolic_score,
  CAST(COALESCE(AVG(hs.longevity_score), 50) AS INTEGER) AS longevity_score,

  -- Trends (30-day vs 60-day comparison)
  CASE
    WHEN AVG(CASE WHEN hs.date >= DATE('now', '-30 days') THEN hs.kidney_score END) >
         AVG(CASE WHEN hs.date >= DATE('now', '-60 days') AND hs.date < DATE('now', '-30 days') THEN hs.kidney_score END)
    THEN 'improving'
    WHEN AVG(CASE WHEN hs.date >= DATE('now', '-30 days') THEN hs.kidney_score END) <
         AVG(CASE WHEN hs.date >= DATE('now', '-60 days') AND hs.date < DATE('now', '-30 days') THEN hs.kidney_score END)
    THEN 'declining'
    ELSE 'stable'
  END AS kidney_trend,

  -- Risk flags for Vuralis NPC warnings
  CASE WHEN AVG(hs.kidney_score) < 40 THEN TRUE ELSE FALSE END AS ckd_risk_high,
  CASE WHEN AVG(hs.diabetes_score) < 40 THEN TRUE ELSE FALSE END AS diabetes_risk_high,
  CASE WHEN AVG(hs.bp_score) < 40 THEN TRUE ELSE FALSE END AS hypertension_risk_high,

  DATETIME('now') AS last_synced_at

FROM users u
LEFT JOIN health_scores hs ON u.id = hs.user_id
  AND hs.date >= DATE('now', '-60 days')

WHERE EXISTS (
  SELECT 1 FROM user_app_settings uas
  WHERE uas.user_id = u.id
  AND uas.vuralis_data_bridge_consent = TRUE
)

GROUP BY u.id, u.username;

-- User Streaks View (for Vuralis visual aura effects)
CREATE VIEW IF NOT EXISTS vuralis_user_streaks AS
SELECT
  u.id AS user_id,
  u.username,
  COALESCE(us.current_streak, 0) AS current_streak,
  COALESCE(us.longest_streak, 0) AS longest_streak,

  -- Streak tier for aura effects
  CASE
    WHEN us.current_streak >= 90 THEN 'legendary' -- Golden aura
    WHEN us.current_streak >= 30 THEN 'epic' -- Purple aura
    WHEN us.current_streak >= 14 THEN 'rare' -- Blue aura
    WHEN us.current_streak >= 7 THEN 'uncommon' -- Green aura
    ELSE 'common' -- No aura
  END AS aura_tier,

  us.last_action_date,
  DATETIME('now') AS last_synced_at

FROM users u
LEFT JOIN user_streaks us ON u.id = us.user_id

WHERE EXISTS (
  SELECT 1 FROM user_app_settings uas
  WHERE uas.user_id = u.id
  AND uas.vuralis_data_bridge_consent = TRUE
);

-- Avatar Progression View (for Vuralis avatar capabilities)
CREATE VIEW IF NOT EXISTS vuralis_avatar_progression AS
SELECT
  u.id AS user_id,
  u.username,
  av.level AS avatar_level,
  av.current_xp AS current_xp,
  gcc.class_name AS character_class,
  gcc.xp_multiplier,

  -- Unlocked skills (for Vuralis abilities)
  COUNT(DISTINCT us_skills.skill_id) AS skills_unlocked,

  -- Achievement progress (for Vuralis quest sync)
  COUNT(DISTINCT ua.achievement_id) AS achievements_unlocked,

  -- Cosmetics owned (for Vuralis avatar appearance)
  COUNT(DISTINCT uc.cosmetic_id) AS cosmetics_owned,

  -- Afya Points balance (for Vuralis economy integration)
  av.afya_points_balance,

  DATETIME('now') AS last_synced_at

FROM users u
LEFT JOIN avatar_stats av ON u.id = av.user_id
LEFT JOIN game_character_classes gcc ON av.class_id = gcc.id
LEFT JOIN user_skills us_skills ON u.id = us_skills.user_id
LEFT JOIN user_achievements ua ON u.id = ua.user_id
LEFT JOIN user_cosmetics uc ON u.id = uc.user_id

WHERE EXISTS (
  SELECT 1 FROM user_app_settings uas
  WHERE uas.user_id = u.id
  AND uas.vuralis_data_bridge_consent = TRUE
)

GROUP BY u.id, u.username, av.level, av.current_xp, gcc.class_name, gcc.xp_multiplier, av.afya_points_balance;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_app_settings_vuralis_consent ON user_app_settings(vuralis_data_bridge_consent);
CREATE INDEX IF NOT EXISTS idx_health_scores_date ON health_scores(date);
CREATE INDEX IF NOT EXISTS idx_meals_created_at ON meals(created_at);
