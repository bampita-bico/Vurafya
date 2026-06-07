-- Migration 012: Create Streak Multipliers
-- Date: 2026-04-11
-- Purpose: Define streak bonus multipliers for XP calculation

CREATE TABLE streak_multipliers (
  id SERIAL PRIMARY KEY,
  min_streak_days INTEGER NOT NULL,
  max_streak_days INTEGER,
  multiplier DOUBLE PRECISION NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO streak_multipliers (min_streak_days, max_streak_days, multiplier, description) VALUES
(1, 6, 1.0, 'No bonus for streaks under 7 days'),
(7, 13, 1.2, '7-day streak: +20% XP bonus'),
(14, 29, 1.5, '14-day streak: +50% XP bonus'),
(30, 89, 2.0, '30-day streak: +100% XP bonus (double XP)'),
(90, NULL, 3.0, '90-day streak: +200% XP bonus (triple XP)');

CREATE INDEX idx_streak_multipliers_range ON streak_multipliers(min_streak_days, max_streak_days);
