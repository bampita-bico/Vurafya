-- Migration 003: Seed Character Classes
-- Date: 2026-04-11
-- Purpose: Create 5 character classes with CKD-first design

INSERT OR IGNORE INTO game_character_classes (class_name, focus_area, xp_multiplier, base_hp, starting_skills, description, icon_ref) VALUES
-- PRIMARY: CKD-focused class (highest multiplier)
('The Alchemist', 'CKD Nutrition', 1.3, 100,
 '[1]', -- Meal Logger Pro
 'Master of kidney-safe nutrition and food chemistry. Excels at PRAL tracking, K/P limit management, and discovering CKD-safe food combinations. Perfect for patients managing Chronic Kidney Disease through diet.',
 '/icons/classes/alchemist.svg'),

-- PRIMARY: CKD medication focus
('The Healer', 'Clinical/CKD', 1.25, 100,
 '[3]', -- Med Scheduler
 'Clinical precision expert focused on medication adherence and biometric tracking. Excels at managing CKD medications, dialysis schedules, and lab test tracking. Critical for chronic disease management.',
 '/icons/classes/healer.svg'),

-- SECONDARY: Hypertension focus
('The Warrior', 'Fitness/HTN', 1.15, 120,
 '[2]', -- Hydration Tracker
 'Builds cardiovascular strength through consistent activity. Gains bonuses from step tracking, exercise logging, and BP monitoring. Ideal for hypertension management through fitness.',
 '/icons/classes/warrior.svg'),

-- SECONDARY: Diabetes focus
('The Guardian', 'DM Prevention', 1.15, 130,
 '[4]', -- Biometric Logger
 'Protects future health through preventive action and glucose control. Focuses on diabetes management, HbA1c tracking, and long-term habit consistency. Guards against diabetic complications.',
 '/icons/classes/guardian.svg'),

-- TERTIARY: Mental health
('The Sage', 'Mental Health', 1.1, 110,
 '[]', -- No starting skills
 'Achieves holistic wellness through mindfulness and mental balance. Focuses on sleep quality, stress management, and meditation. Supports overall health improvement through mental resilience.',
 '/icons/classes/sage.svg');
