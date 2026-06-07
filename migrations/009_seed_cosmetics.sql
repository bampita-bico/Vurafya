-- Migration 009: Seed Cosmetics
-- Date: 2026-04-11
-- Purpose: Create 25+ cosmetic items across all rarity levels

-- COMMON COSMETICS (Easy to unlock, low cost)
INSERT OR IGNORE INTO avatar_cosmetics (cosmetic_name, cosmetic_type, rarity, unlock_method, cost_afya_points, image_ref) VALUES
('Basic Headband', 'hat', 'common', 'purchase', 100, '/cosmetics/headband_basic.svg'),
('Simple Outfit', 'outfit', 'common', 'purchase', 150, '/cosmetics/outfit_simple.svg'),
('Bronze Frame', 'badge_frame', 'common', 'achievement', 0, '/cosmetics/frame_bronze.svg'),
('Plain Background', 'background', 'common', 'purchase', 80, '/cosmetics/bg_plain.svg');

-- UNCOMMON COSMETICS (Moderate unlock difficulty)
INSERT OR IGNORE INTO avatar_cosmetics (cosmetic_name, cosmetic_type, rarity, unlock_method, cost_afya_points, image_ref) VALUES
('Running Cap', 'hat', 'uncommon', 'quest', 0, '/cosmetics/cap_running.svg'),
('Fitness Gear', 'outfit', 'uncommon', 'purchase', 300, '/cosmetics/outfit_fitness.svg'),
('Silver Frame', 'badge_frame', 'uncommon', 'achievement', 0, '/cosmetics/frame_silver.svg'),
('Health Tracker Watch', 'accessory', 'uncommon', 'purchase', 250, '/cosmetics/watch_tracker.svg'),
('Nature Background', 'background', 'uncommon', 'purchase', 200, '/cosmetics/bg_nature.svg');

-- RARE COSMETICS (Quest/Achievement unlocks or higher cost)
INSERT OR IGNORE INTO avatar_cosmetics (cosmetic_name, cosmetic_type, rarity, unlock_method, cost_afya_points, image_ref) VALUES
('Alchemist Hat', 'hat', 'rare', 'achievement', 0, '/cosmetics/hat_alchemist.svg'),
('Warrior Armor', 'outfit', 'rare', 'quest', 0, '/cosmetics/outfit_warrior.svg'),
('Gold Frame', 'badge_frame', 'rare', 'achievement', 0, '/cosmetics/frame_gold.svg'),
('Health Aura', 'effect', 'rare', 'purchase', 800, '/cosmetics/aura_health.svg'),
('Lab Coat', 'outfit', 'rare', 'achievement', 0, '/cosmetics/outfit_labcoat.svg'),
('City Background', 'background', 'rare', 'purchase', 600, '/cosmetics/bg_city.svg');

-- EPIC COSMETICS (Major achievements, CKD-focused)
INSERT OR IGNORE INTO avatar_cosmetics (cosmetic_name, cosmetic_type, rarity, unlock_method, cost_afya_points, image_ref) VALUES
('CKD Guardian Crown', 'hat', 'epic', 'achievement', 0, '/cosmetics/crown_ckd.svg'),
('Kidney Protector Armor', 'outfit', 'epic', 'achievement', 0, '/cosmetics/outfit_kidney_protector.svg'),
('Sage Robes', 'outfit', 'epic', 'seasonal', 0, '/cosmetics/outfit_sage.svg'),
('Platinum Frame', 'badge_frame', 'epic', 'achievement', 0, '/cosmetics/frame_platinum.svg'),
('Healing Aura', 'effect', 'epic', 'purchase', 2000, '/cosmetics/aura_healing.svg'),
('Dialysis Hero Badge', 'accessory', 'epic', 'achievement', 0, '/cosmetics/badge_dialysis.svg');

-- LEGENDARY COSMETICS (Ultimate unlocks)
INSERT OR IGNORE INTO avatar_cosmetics (cosmetic_name, cosmetic_type, rarity, unlock_method, cost_afya_points, image_ref) VALUES
('Immortal Halo', 'hat', 'legendary', 'achievement', 0, '/cosmetics/halo_immortal.svg'),
('Health Oracle Robes', 'outfit', 'legendary', 'achievement', 0, '/cosmetics/outfit_oracle.svg'),
('Legendary Aura', 'effect', 'legendary', 'achievement', 0, '/cosmetics/aura_legendary.svg'),
('Diamond Frame', 'badge_frame', 'legendary', 'achievement', 0, '/cosmetics/frame_diamond.svg'),
('Kidney Champion Wings', 'accessory', 'legendary', 'achievement', 0, '/cosmetics/wings_kidney_champion.svg');

-- SEASONAL COSMETICS (Limited-time events)
INSERT OR IGNORE INTO avatar_cosmetics (cosmetic_name, cosmetic_type, rarity, unlock_method, cost_afya_points, image_ref) VALUES
('Ramadan Crescent Hat', 'hat', 'rare', 'seasonal', 0, '/cosmetics/hat_ramadan.svg'),
('World Kidney Day Badge', 'accessory', 'epic', 'seasonal', 0, '/cosmetics/badge_wkd.svg'),
('Diabetes Awareness Ribbon', 'accessory', 'rare', 'seasonal', 0, '/cosmetics/ribbon_diabetes.svg');
