-- Migration 007: Seed Quests (CKD-First)
-- Date: 2026-04-11
-- Purpose: Create daily/weekly/monthly/seasonal quests with CKD priority

-- DAILY CKD QUESTS (Highest rewards)
INSERT OR IGNORE INTO game_quests (name, quest_type, description, xp_reward, points_reward, duration_days, condition_focus, min_level_required) VALUES
('Kidney-Safe Day', 'daily', 'Keep K/P within limits and log all meals today', 150, 40, 1, 'CKD', 1),
('Low K/P Challenge', 'daily', 'Stay under potassium and phosphorus limits today', 120, 30, 1, 'CKD', 1),
('PRAL Perfect Day', 'daily', 'Maintain kidney-safe PRAL score for the day', 130, 35, 1, 'CKD', 3),
('Sodium Watch Day', 'daily', 'Keep sodium under 2000mg today', 100, 25, 1, 'CKD', 1);

-- DAILY GENERAL QUESTS
INSERT OR IGNORE INTO game_quests (name, quest_type, description, xp_reward, points_reward, duration_days, condition_focus, min_level_required) VALUES
('3-Day Water Sprint', 'daily', 'Drink 8 glasses of water for 3 consecutive days', 100, 25, 3, 'General', 1),
('Perfect Day Challenge', 'daily', 'Log all meals and medications today', 150, 40, 1, 'General', 1),
('Med Adherence Day', 'daily', 'Take all medications on time today', 200, 50, 1, 'General', 1);

-- WEEKLY CKD QUESTS (High rewards)
INSERT OR IGNORE INTO game_quests (name, quest_type, description, xp_reward, points_reward, duration_days, condition_focus, min_level_required) VALUES
('Kidney Safe Week', 'weekly', 'Maintain kidney-safe K/P limits for 7 days', 1000, 250, 7, 'CKD', 1),
('PRAL Perfect Week', 'weekly', 'Keep PRAL in kidney-safe range for 7 days', 1200, 300, 7, 'CKD', 3),
('Dialysis Prep Week', 'weekly', 'Complete all dialysis sessions and track fluids', 800, 200, 7, 'CKD', 5),
('CKD Med Perfect Week', 'weekly', 'Perfect CKD medication adherence for 7 days', 1000, 250, 7, 'CKD', 1),
('Phosphate Binder Week', 'weekly', 'Take phosphate binders correctly for 7 days', 900, 225, 7, 'CKD', 3);

-- WEEKLY SECONDARY QUESTS (DM/HTN)
INSERT OR IGNORE INTO game_quests (name, quest_type, description, xp_reward, points_reward, duration_days, condition_focus, min_level_required) VALUES
('Glucose Control Week', 'weekly', 'Log blood sugar 3x daily for 7 days', 600, 150, 7, 'Diabetes', 1),
('Low GI Week', 'weekly', 'Choose low-GI foods for 7 consecutive days', 700, 175, 7, 'Diabetes', 2),
('BP Perfect Week', 'weekly', 'Log BP daily and stay in healthy range', 600, 150, 7, 'Hypertension', 1),
('DASH Diet Week', 'weekly', 'Follow DASH diet principles for 7 days', 800, 200, 7, 'Hypertension', 2);

-- WEEKLY GENERAL QUESTS
INSERT OR IGNORE INTO game_quests (name, quest_type, description, xp_reward, points_reward, duration_days, condition_focus, min_level_required) VALUES
('Protein Power Week', 'weekly', 'Hit protein target 6/7 days', 500, 125, 7, 'General', 1),
('Step God Challenge', 'weekly', '10,000 steps/day for 7 days', 700, 175, 7, 'General', 2),
('Hydration Champion Week', 'weekly', '8+ glasses daily for 7 days', 400, 100, 7, 'General', 1);

-- MONTHLY CKD QUESTS (Highest rewards)
INSERT OR IGNORE INTO game_quests (name, quest_type, description, xp_reward, points_reward, duration_days, condition_focus, min_level_required) VALUES
('CKD Diet Champion Month', 'monthly', 'Perfect kidney-safe diet for 30 days', 3000, 750, 30, 'CKD', 5),
('Kidney Function Improver', 'monthly', 'Maintain/improve kidney scores for 30 days', 3500, 900, 30, 'CKD', 5),
('CKD Med Perfect Month', 'monthly', '100% CKD medication adherence for 30 days', 3000, 750, 30, 'CKD', 3),
('PRAL Master Month', 'monthly', 'Kidney-safe PRAL for 30 consecutive days', 2800, 700, 30, 'CKD', 5);

-- MONTHLY SECONDARY QUESTS
INSERT OR IGNORE INTO game_quests (name, quest_type, description, xp_reward, points_reward, duration_days, condition_focus, min_level_required) VALUES
('Glucose Control Master', 'monthly', 'Stable blood sugar for 30 days', 2000, 500, 30, 'Diabetes', 5),
('BP Stability Month', 'monthly', 'Healthy BP range for 30 days', 2000, 500, 30, 'Hypertension', 5);

-- MONTHLY GENERAL QUESTS
INSERT OR IGNORE INTO game_quests (name, quest_type, description, xp_reward, points_reward, duration_days, condition_focus, min_level_required) VALUES
('30-Day Transformation', 'monthly', 'Log meals + meds daily for 30 days', 1500, 400, 30, 'General', 1),
('Med Champion Month', 'monthly', 'Perfect medication adherence for 30 days', 2000, 500, 30, 'General', 3);

-- SEASONAL QUESTS (CKD-first)
INSERT OR IGNORE INTO game_quests (name, quest_type, description, xp_reward, points_reward, duration_days, condition_focus, min_level_required) VALUES
('World Kidney Day Sprint 2025', 'seasonal', 'Complete CKD challenges during March 2025', 3500, 900, 30, 'CKD', 1),
('Ramadan Wellness Challenge', 'seasonal', 'Healthy fasting and nutrition during Ramadan', 2500, 600, 30, 'General', 1),
('Diabetes Awareness Month', 'seasonal', 'Glucose control challenges during November', 2500, 600, 30, 'Diabetes', 1);

-- STORY QUESTS (Progressive narrative)
INSERT OR IGNORE INTO game_quests (name, quest_type, description, xp_reward, points_reward, duration_days, condition_focus, min_level_required) VALUES
('The Journey Begins', 'story', 'Complete your first week of health tracking', 300, 75, 7, 'General', 1),
('Mastering CKD Nutrition', 'story', 'Learn and apply kidney-safe diet principles', 1000, 250, 14, 'CKD', 5),
('Clinical Excellence', 'story', 'Master medication adherence and lab tracking', 1500, 400, 21, 'General', 10);
