-- Migration 011: Create XP Rules
-- Date: 2026-04-11
-- Purpose: Define XP earning rules for all health actions

CREATE TABLE xp_rules (
  id SERIAL PRIMARY KEY,
  action_type VARCHAR(40) UNIQUE NOT NULL,
  base_xp INTEGER NOT NULL,
  description TEXT,
  requires_verification BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Meal Logging
INSERT INTO xp_rules (action_type, base_xp, description, requires_verification) VALUES
('meal_logged', 10, 'Base XP for logging any meal', FALSE),
('meal_logged_complete_macros', 15, 'XP when all macros tracked accurately', FALSE),
('meal_logged_photo', 18, 'XP when photo attached to meal', FALSE),
('meal_kidney_safe', 25, 'Bonus XP for kidney-safe meal (CKD focus)', FALSE);

-- Hydration
INSERT INTO xp_rules (action_type, base_xp, description, requires_verification) VALUES
('water_logged', 5, 'XP per glass of water logged', FALSE),
('hydration_goal_met', 20, 'Bonus for hitting daily water goal (8+ glasses)', FALSE);

-- Medication Adherence (CRITICAL for CKD)
INSERT INTO xp_rules (action_type, base_xp, description, requires_verification) VALUES
('medication_taken_on_time', 25, 'Med taken within scheduled window', FALSE),
('medication_taken_late', 10, 'Med taken but outside window', FALSE),
('ckd_medication_taken', 35, 'CKD-specific medication taken (highest priority)', FALSE),
('dialysis_session_completed', 100, 'Dialysis session completed', TRUE);

-- Biometrics Logging
INSERT INTO xp_rules (action_type, base_xp, description, requires_verification) VALUES
('blood_pressure_logged', 15, 'BP measurement logged', FALSE),
('blood_sugar_logged', 15, 'Glucose measurement logged', FALSE),
('weight_logged', 10, 'Weight measurement logged', FALSE),
('egfr_logged', 25, 'Kidney function (eGFR) logged - CKD focus', FALSE);

-- Clinical Actions (High XP, verification required)
INSERT INTO xp_rules (action_type, base_xp, description, requires_verification) VALUES
('lab_test_completed', 100, 'Lab test completed at partner facility', TRUE),
('kidney_function_test', 150, 'Kidney function panel completed (CKD priority)', TRUE),
('consultation_attended', 150, 'Medical consultation attended', TRUE),
('screening_completed', 80, 'Preventive screening completed', TRUE);

-- Nutrition Goals (Daily targets)
INSERT INTO xp_rules (action_type, base_xp, description, requires_verification) VALUES
('daily_protein_target_hit', 20, 'Hit protein target for the day', FALSE),
('daily_sodium_limit_met', 30, 'CKD: stayed under sodium limit (2000mg)', FALSE),
('daily_potassium_limit_met', 30, 'CKD: stayed under potassium limit', FALSE),
('daily_phosphorus_limit_met', 30, 'CKD: stayed under phosphorus limit', FALSE),
('daily_pral_safe', 35, 'CKD: maintained kidney-safe PRAL score', FALSE),
('daily_step_goal_hit', 25, 'Hit step count goal (10,000 steps)', FALSE),
('perfect_adherence_day', 50, 'All meds taken + all meals logged', FALSE);

-- Social Actions
INSERT INTO xp_rules (action_type, base_xp, description, requires_verification) VALUES
('quest_objective_completed', 0, 'XP from quest definition', FALSE),
('challenge_completed', 0, 'XP from challenge definition', FALSE),
('leaderboard_win_first', 500, 'Top 1 in leaderboard', FALSE),
('leaderboard_win_top3', 300, 'Top 2-3 in leaderboard', FALSE),
('leaderboard_win_top10', 150, 'Top 4-10 in leaderboard', FALSE),
('friend_invited', 50, 'Invited friend who joined', FALSE),
('friend_helped', 15, 'Endorsed friend achievement', FALSE);

CREATE INDEX idx_xp_rules_action ON xp_rules(action_type);
CREATE INDEX idx_xp_rules_active ON xp_rules(is_active);
