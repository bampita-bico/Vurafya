-- Migration 010: Seed Seasonal Events
-- Date: 2026-04-11
-- Purpose: Create seasonal events with CKD-first priority

-- World Kidney Day (PRIMARY - CKD focus) - March 13, 2025
INSERT OR IGNORE INTO season_pass_metadata (season_name, theme, starts_at, ends_at, exclusive_quests, exclusive_rewards) VALUES
('World Kidney Day 2025',
 'Global kidney health awareness, CKD prevention and management, kidney-safe nutrition challenges',
 '2025-03-01',
 '2025-03-31',
 '[18,31]', -- Quest IDs: World Kidney Day Sprint, Kidney Safe Week
 '[46,47,48]'), -- Cosmetic IDs: CKD Guardian Crown, Kidney Protector Armor, World Kidney Day Badge

-- Ramadan Wellness Season (General health during fasting)
('Ramadan Wellness 2025',
 'Spiritual health, fasting nutrition, hydration management, and community support during Ramadan',
 '2025-02-28',
 '2025-04-02',
 '[19,13]', -- Quest IDs: Ramadan Wellness Challenge, Hydration Champion Week
 '[50,51]'), -- Cosmetic IDs: Ramadan Crescent Hat, Sage Robes

-- Diabetes Awareness Month (SECONDARY focus)
('Diabetes Awareness Month 2025',
 'Glucose control mastery, diabetes management education, and HbA1c optimization',
 '2025-11-01',
 '2025-11-30',
 '[9,20]', -- Quest IDs: Glucose Control Week, Diabetes Awareness Month quest
 '[52,53]'), -- Cosmetic IDs: Diabetes Awareness Ribbon, Glucose Guardian cosmetic

-- World Health Day (General health)
('World Health Day 2025',
 'Global health awareness and preventive screenings',
 '2025-04-01',
 '2025-04-30',
 '[23]', -- Quest IDs: General health challenges
 '[54]'), -- Cosmetic IDs: World Health Day badge

-- Hypertension Awareness Month (SECONDARY focus)
('Heart Health Month 2025',
 'Blood pressure management, DASH diet, cardiovascular health',
 '2025-05-01',
 '2025-05-31',
 '[11]', -- Quest IDs: BP Perfect Week
 '[55]'), -- Cosmetic IDs: Heart Health badge

-- New Year Health Reset
('New Year Health Reset 2026',
 'Start the year strong with new health habits and goal setting',
 '2026-01-01',
 '2026-01-31',
 '[23]', -- Quest IDs: 30-Day Transformation
 '[56]'); -- Cosmetic IDs: New Year badge
