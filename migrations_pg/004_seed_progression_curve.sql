-- Migration 004: Seed Progression Curve
-- Date: 2026-04-11
-- Purpose: Create XP progression curve for levels 1-50 (Formula: 100 × level^1.5)

INSERT INTO character_progression (class_id, level, xp_required, title_unlocked)
SELECT
  c.id AS class_id,
  l.level,
  CAST(100 * POWER(l.level, 1.5) AS INTEGER) AS xp_required,
  CASE
    WHEN l.level = 1 THEN 'Health Novice'
    WHEN l.level = 5 THEN 'Consistency Keeper'
    WHEN l.level = 10 THEN 'Health Enthusiast'
    WHEN l.level = 15 THEN CASE c.class_name
      WHEN 'The Alchemist' THEN 'CKD Diet Master'
      WHEN 'The Warrior' THEN 'Fitness Champion'
      WHEN 'The Sage' THEN 'Mindfulness Master'
      WHEN 'The Healer' THEN 'Clinical Expert'
      WHEN 'The Guardian' THEN 'Diabetes Guardian'
    END
    WHEN l.level = 20 THEN 'Wellness Champion'
    WHEN l.level = 25 THEN CASE c.class_name
      WHEN 'The Alchemist' THEN 'Kidney Nutrition Sage'
      WHEN 'The Warrior' THEN 'Hypertension Warrior'
      WHEN 'The Sage' THEN 'Balance Master'
      WHEN 'The Healer' THEN 'Adherence Hero'
      WHEN 'The Guardian' THEN 'Prevention Expert'
    END
    WHEN l.level = 30 THEN CASE c.class_name
      WHEN 'The Alchemist' THEN 'CKD Nutrition Guardian'
      WHEN 'The Warrior' THEN 'Endurance Legend'
      WHEN 'The Sage' THEN 'Zen Master'
      WHEN 'The Healer' THEN 'Clinical Perfectionist'
      WHEN 'The Guardian' THEN 'Longevity Guardian'
    END
    WHEN l.level = 40 THEN 'Health Legend'
    WHEN l.level = 50 THEN 'Immortal'
    ELSE NULL
  END AS title_unlocked
FROM game_character_classes c
CROSS JOIN (
  SELECT 1 AS level UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL
  SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL
  SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL
  SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20 UNION ALL
  SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23 UNION ALL SELECT 24 UNION ALL SELECT 25 UNION ALL
  SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28 UNION ALL SELECT 29 UNION ALL SELECT 30 UNION ALL
  SELECT 31 UNION ALL SELECT 32 UNION ALL SELECT 33 UNION ALL SELECT 34 UNION ALL SELECT 35 UNION ALL
  SELECT 36 UNION ALL SELECT 37 UNION ALL SELECT 38 UNION ALL SELECT 39 UNION ALL SELECT 40 UNION ALL
  SELECT 41 UNION ALL SELECT 42 UNION ALL SELECT 43 UNION ALL SELECT 44 UNION ALL SELECT 45 UNION ALL
  SELECT 46 UNION ALL SELECT 47 UNION ALL SELECT 48 UNION ALL SELECT 49 UNION ALL SELECT 50
) l;
