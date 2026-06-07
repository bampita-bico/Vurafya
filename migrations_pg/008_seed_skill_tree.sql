-- Migration 008: Seed Skill Tree
-- Date: 2026-04-11
-- Purpose: Create 15 skills across 4 tiers with CKD focus

-- TIER 1: Foundation Skills (No prerequisites, low XP cost)
INSERT INTO skill_tree (skill_name, category, prerequisite_id, xp_cost, description, is_premium) VALUES
('Meal Logger Pro', 'Nutrition', NULL, 500, 'Unlock detailed macro tracking, meal templates, and nutrient synergy insights', FALSE),
('Hydration Tracker', 'Fitness', NULL, 300, 'Advanced water intake reminders, hydration goals, and dehydration alerts', FALSE),
('Med Scheduler', 'Clinical', NULL, 400, 'Complex medication schedules with meal relations and reminder customization', FALSE),
('Biometric Logger', 'Clinical', NULL, 350, 'Track BP, blood sugar, weight with trend analysis and predictions', FALSE);

-- TIER 2: Intermediate Skills (Requires Tier 1, moderate XP cost)
INSERT INTO skill_tree (skill_name, category, prerequisite_id, xp_cost, description, is_premium) VALUES
('Nutrient Master', 'Nutrition', 1, 1000, 'See micronutrient breakdowns, deficiency alerts, and absorption optimization', FALSE),
('CKD Diet Expert', 'Nutrition', 1, 1500, 'Unlock PRAL calculator, K/P tracking, and kidney-safe meal plans (CKD-FOCUSED)', TRUE),
('Diabetes Control', 'Clinical', 4, 1200, 'Glycemic index tracking, insulin calculators, and carb counting tools', TRUE),
('Hypertension Manager', 'Clinical', 4, 1100, 'DASH diet tracker, sodium calculator, BP trend predictions', TRUE),
('Activity Optimizer', 'Fitness', 2, 900, 'Step tracking analysis, exercise recommendations, calorie burn calculations', FALSE);

-- TIER 3: Advanced Skills (Requires Tier 2, high XP cost)
INSERT INTO skill_tree (skill_name, category, prerequisite_id, xp_cost, description, is_premium) VALUES
('Food Alchemist', 'Nutrition', 5, 2500, 'Unlock nutrient synergy recommendations and food pairing optimization', TRUE),
('Clinical Integration', 'Clinical', 7, 3000, 'Connect lab results with AI health insights and predictive analytics', TRUE),
('Longevity Optimizer', 'Prevention', NULL, 3500, 'Comprehensive longevity scoring, biomarker tracking, aging predictions', TRUE),
('Kidney Guardian', 'Clinical', 6, 3200, 'Master CKD management: eGFR tracking, creatinine trends, stage monitoring (CKD-FOCUSED)', TRUE);

-- TIER 4: Master Skills (Requires multiple prerequisites, very high XP cost)
INSERT INTO skill_tree (skill_name, category, prerequisite_id, xp_cost, description, is_premium) VALUES
('Health Oracle', 'AI', 11, 5000, 'AI-powered predictive health modeling and personalized intervention plans', TRUE),
('Community Leader', 'Social', NULL, 2000, 'Create groups, host challenges, mentor new users with coaching tools', FALSE);
