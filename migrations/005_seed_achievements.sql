-- Migration 005: Seed Achievements
-- Date: 2026-04-11
-- Purpose: Create 40+ achievements with CKD-first hierarchy

-- Ensure table exists with proper schema (handled by bootstrap, but making idempotent here)
CREATE TABLE IF NOT EXISTS achievements (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(120) UNIQUE NOT NULL,
  description TEXT,
  icon TEXT,
  requirement_type VARCHAR(40),
  reward_item_id INTEGER,
  points INTEGER DEFAULT 0,
  category VARCHAR(40),
  xp_reward INTEGER DEFAULT 0,
  points_reward INTEGER DEFAULT 0,
  trigger_type VARCHAR(40),
  trigger_value REAL,
  badge_id INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- PRIMARY: CKD Nutrition Achievements (HIGHEST REWARDS)
INSERT OR IGNORE INTO achievements (name, description, category, xp_reward, points_reward, requirement_type, trigger_type, trigger_value) VALUES
('Kidney Diet Master', 'Maintain kidney-safe K/P limits for 14 consecutive days', 'ckd_nutrition', 1500, 400, 'condition', 'streak', 14),
('PRAL Pro 30-Day', 'Keep PRAL within kidney-safe range for 30 days', 'ckd_nutrition', 2000, 500, 'condition', 'streak', 30),
('Potassium Guardian', 'Stay under potassium limit for 21 consecutive days', 'ckd_nutrition', 1200, 300, 'condition', 'streak', 21),
('Low Phosphorus Champion', 'Maintain low phosphorus intake for 21 days', 'ckd_nutrition', 1200, 300, 'condition', 'streak', 21),
('Sodium Limit Master', 'Keep sodium under 2000mg for 30 consecutive days', 'ckd_nutrition', 1500, 400, 'condition', 'streak', 30),
('CKD Protein Balance', 'Hit CKD protein target (0.6-0.8g/kg) for 14 days', 'ckd_nutrition', 1000, 250, 'condition', 'count', 14);

-- PRIMARY: CKD Medication Achievements (HIGHEST REWARDS)
INSERT OR IGNORE INTO achievements (name, description, category, xp_reward, points_reward, requirement_type, trigger_type, trigger_value) VALUES
('Dialysis Warrior', 'Complete all dialysis sessions for 30 days', 'ckd_medication', 2000, 500, 'milestone', 'count', 30),
('CKD Med Perfect Month', 'Take all CKD medications on time for 30 days', 'ckd_medication', 2500, 600, 'streak', 'streak', 30),
('Never Missed CKD Med', 'Perfect CKD medication adherence for 90 days', 'ckd_medication', 5000, 1200, 'streak', 'streak', 90),
('Phosphate Binder Pro', 'Take phosphate binders correctly for 30 days', 'ckd_medication', 1500, 400, 'streak', 'streak', 30);

-- PRIMARY: CKD Clinical Achievements (HIGH REWARDS)
INSERT OR IGNORE INTO achievements (name, description, category, xp_reward, points_reward, requirement_type, trigger_type, trigger_value) VALUES
('eGFR Improver', 'Improve eGFR by 5+ points over 90 days', 'ckd_clinical', 1800, 450, 'condition', 'milestone', 1),
('Creatinine Control', 'Maintain stable creatinine for 60 days', 'ckd_clinical', 1500, 400, 'condition', 'streak', 60),
('Kidney Function Test Hero', 'Complete kidney function panel 3 times', 'ckd_clinical', 1000, 250, 'count', 'count', 3),
('CKD Stage Stabilizer', 'Prevent CKD stage progression for 6 months', 'ckd_clinical', 3000, 750, 'condition', 'milestone', 1);

-- SECONDARY: Diabetes Achievements
INSERT OR IGNORE INTO achievements (name, description, category, xp_reward, points_reward, requirement_type, trigger_type, trigger_value) VALUES
('Glucose Guardian', 'Log blood sugar 3x daily for 14 days', 'diabetes', 800, 200, 'count', 'count', 42),
('HbA1c Master', 'Achieve target HbA1c (<7%) on lab test', 'diabetes', 1000, 250, 'milestone', 'milestone', 1),
('Low GI Champion', 'Choose low-GI foods for 21 consecutive days', 'diabetes', 700, 175, 'streak', 'streak', 21),
('Carb Counter Pro', 'Track carbs accurately for 30 days', 'diabetes', 900, 225, 'streak', 'streak', 30);

-- SECONDARY: Hypertension Achievements
INSERT OR IGNORE INTO achievements (name, description, category, xp_reward, points_reward, requirement_type, trigger_type, trigger_value) VALUES
('BP Tracker', 'Log blood pressure daily for 14 days', 'hypertension', 600, 150, 'count', 'count', 14),
('DASH Diet Pro', 'Follow DASH diet principles for 30 days', 'hypertension', 1000, 250, 'streak', 'streak', 30),
('Sodium Limit Champion', 'Keep sodium <2300mg for 21 days', 'hypertension', 800, 200, 'streak', 'streak', 21),
('BP Control Master', 'Maintain healthy BP (<130/80) for 30 days', 'hypertension', 1200, 300, 'condition', 'streak', 30);

-- TERTIARY: General Nutrition
INSERT OR IGNORE INTO achievements (name, description, category, xp_reward, points_reward, requirement_type, trigger_type, trigger_value) VALUES
('First Meal Logged', 'Log your first meal in Vurafya', 'nutrition', 50, 10, 'milestone', 'milestone', 1),
('Week Warrior', 'Log meals for 7 consecutive days', 'nutrition', 200, 50, 'streak', 'streak', 7),
('Month Master', 'Log meals for 30 consecutive days', 'nutrition', 800, 200, 'streak', 'streak', 30),
('100 Meals', 'Log 100 total meals', 'nutrition', 600, 150, 'count', 'count', 100),
('Protein Power', 'Hit daily protein target for 7 days', 'nutrition', 300, 75, 'count', 'count', 7),
('Macro Master', 'Track all macros accurately for 14 days', 'nutrition', 500, 125, 'streak', 'streak', 14);

-- TERTIARY: Hydration
INSERT OR IGNORE INTO achievements (name, description, category, xp_reward, points_reward, requirement_type, trigger_type, trigger_value) VALUES
('Hydration Hero', 'Track water intake for 7 days', 'hydration', 150, 30, 'streak', 'streak', 7),
('8 Glasses Champion', 'Drink 8+ glasses daily for 14 days', 'hydration', 300, 75, 'count', 'count', 14),
('Hydration Legend', '30-day perfect hydration streak', 'hydration', 800, 200, 'streak', 'streak', 30);

-- TERTIARY: General Clinical
INSERT OR IGNORE INTO achievements (name, description, category, xp_reward, points_reward, requirement_type, trigger_type, trigger_value) VALUES
('First Lab Test', 'Complete your first lab test booking', 'clinical', 200, 50, 'milestone', 'milestone', 1),
('Health Screener', 'Complete 3 preventive screenings', 'clinical', 800, 200, 'count', 'count', 3),
('Annual Checkup', 'Complete comprehensive annual screening', 'clinical', 1000, 250, 'milestone', 'milestone', 1),
('Med Adherence Week', 'Perfect medication adherence for 7 days', 'clinical', 400, 100, 'streak', 'streak', 7);

-- TERTIARY: Social
INSERT OR IGNORE INTO achievements (name, description, category, xp_reward, points_reward, requirement_type, trigger_type, trigger_value) VALUES
('Team Player', 'Join your first health challenge', 'social', 100, 25, 'milestone', 'milestone', 1),
('Support Squad', 'Complete a group challenge', 'social', 500, 125, 'milestone', 'milestone', 1),
('Friend Network', 'Connect with 10 health friends', 'social', 400, 100, 'count', 'count', 10),
('Challenge Champion', 'Win 5 friend challenges', 'social', 600, 150, 'count', 'count', 5);

-- TERTIARY: Milestones
INSERT OR IGNORE INTO achievements (name, description, category, xp_reward, points_reward, requirement_type, trigger_type, trigger_value) VALUES
('7-Day Streak', 'Log in daily for 7 consecutive days', 'milestone', 250, 60, 'streak', 'streak', 7),
('30-Day Legend', 'Log in daily for 30 consecutive days', 'milestone', 1000, 250, 'streak', 'streak', 30),
('Level 10 Champion', 'Reach Level 10', 'milestone', 1500, 400, 'condition', 'milestone', 10),
('Level 20 Master', 'Reach Level 20', 'milestone', 3000, 750, 'condition', 'milestone', 20),
('Level 30 Legend', 'Reach Level 30', 'milestone', 5000, 1200, 'condition', 'milestone', 30),
('All Classes Tried', 'Experience all 5 character classes', 'milestone', 3000, 750, 'count', 'count', 5);
