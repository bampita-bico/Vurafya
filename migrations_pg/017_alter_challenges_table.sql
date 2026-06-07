-- Migration 017: Alter Challenges Table
-- Date: 2026-04-11
-- Purpose: Add competition-related fields to challenges table

-- Add competition fields to challenges table
ALTER TABLE challenges ADD COLUMN metric VARCHAR(40); -- meals_logged / steps / health_score / adherence
ALTER TABLE challenges ADD COLUMN leaderboard_type VARCHAR(40); -- individual / group / team
ALTER TABLE challenges ADD COLUMN prize_pool_afya_points INTEGER DEFAULT 0;
ALTER TABLE challenges ADD COLUMN is_team_challenge BOOLEAN DEFAULT FALSE;
ALTER TABLE challenges ADD COLUMN max_participants INTEGER;
ALTER TABLE challenges ADD COLUMN current_participants INTEGER DEFAULT 0;

-- Add tracking for challenge participants (separate table for clarity)
CREATE TABLE IF NOT EXISTS challenge_participants (
  id SERIAL PRIMARY KEY,
  challenge_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  current_value DOUBLE PRECISION DEFAULT 0, -- Current progress metric value
  rank INTEGER, -- Current rank within challenge
  joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (challenge_id) REFERENCES challenges(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE (challenge_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_challenge_participants_challenge ON challenge_participants(challenge_id);
CREATE INDEX IF NOT EXISTS idx_challenge_participants_user ON challenge_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_challenge_participants_rank ON challenge_participants(challenge_id, rank);
