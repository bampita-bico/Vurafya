-- Migration 079: Crafting System
-- Meals-as-potions: logging real food combos creates "potions"
-- Quality based on nutritional balance. Condition-relevant crafts = bonus

-- ============================================================================
-- CRAFTING QUALITY TIERS
-- ============================================================================

CREATE TABLE IF NOT EXISTS crafting_quality_tiers (
    id INTEGER PRIMARY KEY,
    tier_name VARCHAR(20) NOT NULL UNIQUE,
    tier_level INTEGER NOT NULL UNIQUE,
    min_quality_score REAL NOT NULL,
    xp_multiplier REAL NOT NULL DEFAULT 1.0,
    ap_bonus INTEGER DEFAULT 0,
    color_hex VARCHAR(10),
    requires_subscription_tier INTEGER DEFAULT 1,
        -- 1=Common/Uncommon free, 2=Rare for Plus, 3=Epic/Legendary for Pro
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- CRAFTING RECIPES
-- ============================================================================

CREATE TABLE IF NOT EXISTS crafting_recipes (
    id INTEGER PRIMARY KEY,
    recipe_name VARCHAR(120) NOT NULL,
    recipe_type VARCHAR(40) NOT NULL,
        -- potion, elixir, tonic, feast, remedy
    description TEXT,
    condition_focus VARCHAR(60),
        -- CKD, Diabetes, Hypertension, General
    required_food_categories TEXT NOT NULL,
        -- JSON: e.g., ["protein","vegetable","grain"]
    required_food_count INTEGER DEFAULT 3,
    quality_formula TEXT,
        -- How quality score is calculated from nutrition
    base_xp_reward INTEGER DEFAULT 10,
    base_ap_reward INTEGER DEFAULT 2,
    effect_description TEXT,
        -- In-game effect of the crafted item
    effect_duration_hours INTEGER DEFAULT 24,
    requires_subscription_tier INTEGER DEFAULT 1,
    min_crafting_level INTEGER DEFAULT 1,
    cooldown_hours INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- CRAFTING MATERIALS (maps foods to crafting properties)
-- ============================================================================

CREATE TABLE IF NOT EXISTS crafting_materials (
    id INTEGER PRIMARY KEY,
    food_id INTEGER NOT NULL REFERENCES foods(id),
    material_name VARCHAR(80),
    material_category VARCHAR(40) NOT NULL,
        -- protein_essence, vegetable_extract, grain_base, fruit_juice,
        -- mineral_crystal, herb_spice, fat_oil, dairy_cream
    quality_contribution REAL DEFAULT 1.0,
        -- How much this food contributes to recipe quality
    rarity VARCHAR(20) DEFAULT 'common',
        -- common, uncommon, rare, epic
    condition_bonus_for VARCHAR(60),
        -- If this material gives extra quality for a specific condition
    condition_bonus_multiplier REAL DEFAULT 1.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(food_id)
);

-- ============================================================================
-- USER CRAFTING INVENTORY
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_crafting_inventory (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    recipe_id INTEGER NOT NULL REFERENCES crafting_recipes(id),
    crafted_name VARCHAR(120),
    quality_tier_id INTEGER REFERENCES crafting_quality_tiers(id),
    quality_score REAL,
    food_ids_used TEXT,
        -- JSON array of food IDs used
    meal_id INTEGER,
        -- Links to the actual meal logged
    xp_earned INTEGER DEFAULT 0,
    ap_earned INTEGER DEFAULT 0,
    effect_active BOOLEAN DEFAULT FALSE,
    effect_expires_at TIMESTAMP,
    crafted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- USER CRAFTING MASTERY
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_crafting_mastery (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    recipe_type VARCHAR(40) NOT NULL,
    mastery_level INTEGER DEFAULT 1,
    mastery_xp INTEGER DEFAULT 0,
    total_crafted INTEGER DEFAULT 0,
    highest_quality_achieved INTEGER DEFAULT 1,
    last_crafted_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, recipe_type)
);

-- ============================================================================
-- CRAFTING CONDITION BONUSES
-- ============================================================================

CREATE TABLE IF NOT EXISTS crafting_condition_bonuses (
    id INTEGER PRIMARY KEY,
    recipe_id INTEGER NOT NULL REFERENCES crafting_recipes(id),
    condition_id INTEGER NOT NULL REFERENCES medical_conditions(id),
    quality_bonus REAL DEFAULT 0.2,
        -- Extra quality score for condition-relevant crafts
    xp_bonus_pct REAL DEFAULT 25.0,
        -- Extra XP percentage
    bonus_description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(recipe_id, condition_id)
);

-- ============================================================================
-- SEED: QUALITY TIERS
-- ============================================================================

INSERT OR IGNORE INTO crafting_quality_tiers (id, tier_name, tier_level, min_quality_score, xp_multiplier, ap_bonus, color_hex, requires_subscription_tier, description) VALUES
(1, 'Common', 1, 0.0, 1.0, 0, '#9CA3AF', 1, 'Basic craft. Nutritionally incomplete or imbalanced.'),
(2, 'Uncommon', 2, 40.0, 1.5, 2, '#22C55E', 1, 'Decent craft. Some nutritional balance achieved.'),
(3, 'Rare', 3, 65.0, 2.0, 5, '#3B82F6', 2, 'Good craft. Well-balanced nutrition.'),
(4, 'Epic', 4, 80.0, 3.0, 10, '#A855F7', 3, 'Excellent craft. Near-perfect nutritional balance.'),
(5, 'Legendary', 5, 95.0, 5.0, 25, '#F59E0B', 3, 'Perfect craft. Optimal nutrition for your condition.');

-- ============================================================================
-- SEED: CRAFTING RECIPES (~20)
-- ============================================================================

INSERT OR IGNORE INTO crafting_recipes (id, recipe_name, recipe_type, description, condition_focus, required_food_categories, required_food_count, quality_formula, base_xp_reward, base_ap_reward, effect_description, effect_duration_hours, requires_subscription_tier, min_crafting_level) VALUES
-- CKD Recipes
(1, 'Alkaline Elixir', 'elixir', 'A meal combo that maximizes alkalizing potential. PRAL-negative foods combined for kidney protection.', 'CKD',
 '["vegetable","grain","legume"]', 3, 'pral_score <= -5.0 ? 100 : max(0, 100 + pral_score * 10)', 25, 5,
 '+10% XP on kidney-safe actions for 24 hours', 24, 1, 1),

(2, 'Kidney Shield Potion', 'potion', 'Low-K, low-P meal combination. Perfect for CKD patients managing electrolytes.', 'CKD',
 '["protein","vegetable","grain"]', 3, 'potassium < 600 AND phosphorus < 300 ? 90 : 50', 30, 8,
 '+15% XP on 3P compliance for 24 hours', 24, 2, 3),

(3, 'Dialysis Recovery Tonic', 'tonic', 'Post-dialysis meal with controlled fluid and balanced nutrition.', 'CKD',
 '["protein","vegetable","fruit"]', 3, 'protein >= 20 AND potassium < 700 ? 85 : 40', 35, 10,
 '+20% XP on dialysis day compliance', 12, 2, 5),

-- Diabetes Recipes
(4, 'Glucose Stabilizer Elixir', 'elixir', 'Low-GI meal combination for stable blood sugar.', 'Diabetes',
 '["protein","vegetable","grain"]', 3, 'glycemic_load < 30 ? 90 : max(0, 90 - glycemic_load)', 25, 5,
 '+10% XP on glucose monitoring for 24 hours', 24, 1, 1),

(5, 'Insulin Sensitivity Brew', 'potion', 'High-fiber, low-sugar meal that supports insulin function.', 'Diabetes',
 '["legume","vegetable","grain"]', 3, 'fiber >= 10 AND sugar < 5 ? 95 : 45', 30, 8,
 '+15% XP on carb counting for 24 hours', 24, 2, 3),

-- Hypertension Recipes
(6, 'DASH Diet Remedy', 'remedy', 'A perfect DASH diet meal: low sodium, high potassium, rich in minerals.', 'Hypertension',
 '["vegetable","fruit","dairy"]', 3, 'sodium < 600 AND potassium > 500 ? 90 : 40', 25, 5,
 '+10% XP on BP logging for 24 hours', 24, 1, 1),

(7, 'Pressure Release Tonic', 'tonic', 'Ultra-low sodium meal with heart-healthy fats.', 'Hypertension',
 '["fish","vegetable","grain"]', 3, 'sodium < 300 ? 95 : max(0, 95 - sodium/10)', 30, 8,
 '+15% XP on sodium tracking for 24 hours', 24, 2, 4),

-- General Health Recipes
(8, 'Vitality Feast', 'feast', 'A well-rounded, nutritionally complete meal covering all major food groups.', 'General',
 '["protein","vegetable","grain","fruit"]', 4, 'all_macros_balanced ? 85 : 50', 20, 4,
 '+5% XP on all actions for 24 hours', 24, 1, 1),

(9, 'Iron Forge Potion', 'potion', 'Iron-rich meal combination with vitamin C for absorption.', 'Hematological',
 '["protein","vegetable","fruit"]', 3, 'iron >= 8 AND vitamin_c >= 30 ? 90 : 40', 25, 5,
 '+15% XP on iron-rich meal logging', 24, 1, 2),

(10, 'Hydration Spring Water', 'tonic', 'A hydrating meal combo with water-rich fruits and vegetables.', 'General',
 '["fruit","vegetable"]', 2, 'water_content_high ? 80 : 40', 15, 3,
 '+10% XP on hydration goals for 12 hours', 12, 1, 1),

(11, 'Protein Power Feast', 'feast', 'High-quality protein from multiple sources for muscle and recovery.', 'General',
 '["protein","legume","dairy"]', 3, 'protein >= 30 AND quality_protein ? 85 : 45', 25, 5,
 '+10% XP on exercise-related actions', 24, 1, 2),

(12, 'Fiber Champion Remedy', 'remedy', 'Maximum fiber meal for gut health and satiety.', 'General',
 '["grain","legume","vegetable"]', 3, 'fiber >= 15 ? 90 : fiber * 6', 20, 4,
 '+10% XP on nutrition logging for 24 hours', 24, 1, 2),

-- Premium Recipes (Pro only)
(13, 'Legendary Kidney Elixir', 'elixir', 'The ultimate CKD meal: perfect PRAL, controlled 3P, all from Pan-African foods.', 'CKD',
 '["protein","vegetable","grain","legume","fruit"]', 5, 'pral <= -8 AND all_3p_under_limits ? 100 : 60', 50, 15,
 '+25% XP on ALL CKD actions for 48 hours', 48, 3, 8),

(14, 'Legendary Sugar Slayer Brew', 'potion', 'Perfect glucose management meal with complex carbs and fiber.', 'Diabetes',
 '["protein","vegetable","grain","legume","fruit"]', 5, 'glycemic_load < 20 AND fiber >= 15 ? 100 : 60', 50, 15,
 '+25% XP on ALL diabetes actions for 48 hours', 48, 3, 8),

(15, 'Legendary Heart Shield', 'remedy', 'Optimal cardiovascular meal: omega-3, low sodium, high minerals.', 'Hypertension',
 '["fish","vegetable","grain","fruit","legume"]', 5, 'sodium < 200 AND omega3_high ? 100 : 60', 50, 15,
 '+25% XP on ALL heart health actions for 48 hours', 48, 3, 8),

(16, 'Pan-African Power Feast', 'feast', 'A legendary feast using traditional Pan-African ingredients for complete nutrition.', 'General',
 '["protein","vegetable","grain","fruit","legume"]', 5, 'nutritionally_complete AND diverse ? 100 : 65', 50, 15,
 '+20% XP on ALL actions for 48 hours', 48, 3, 10),

-- Seasonal/Special
(17, 'Ramadan Iftar Blessing', 'feast', 'Balanced Iftar meal for breaking fast with proper nutrition.', 'General',
 '["protein","fruit","grain"]', 3, 'balanced_macros AND hydrating ? 85 : 50', 30, 8,
 '+15% XP on Ramadan challenge actions', 24, 2, 3),

(18, 'Morning Fuel Tonic', 'tonic', 'Energizing breakfast combination to start the day right.', 'General',
 '["grain","fruit","protein"]', 3, 'balanced_breakfast ? 80 : 40', 15, 3,
 '+5% XP until lunch time', 6, 1, 1),

(19, 'Anti-Gout Remedy', 'remedy', 'Low-purine, high-hydration meal to keep uric acid in check.', 'Gout',
 '["vegetable","grain","dairy"]', 3, 'low_purine AND no_organ_meats ? 90 : 35', 25, 5,
 '+15% XP on gout management actions', 24, 2, 3),

(20, 'Prenatal Nourishment', 'elixir', 'Folate-rich, iron-rich meal for pregnancy health.', 'Maternal',
 '["protein","vegetable","grain","fruit"]', 4, 'folate >= 200 AND iron >= 8 ? 90 : 50', 30, 8,
 '+15% XP on prenatal nutrition logging', 24, 2, 3);

-- ============================================================================
-- SEED: CONDITION BONUSES FOR CRAFTING
-- ============================================================================

INSERT OR IGNORE INTO crafting_condition_bonuses (recipe_id, condition_id, quality_bonus, xp_bonus_pct, bonus_description) VALUES
-- CKD recipes get bonuses for CKD patients
(1, 3, 0.2, 25, 'CKD Stage 3a patient crafting Alkaline Elixir'),
(1, 4, 0.25, 30, 'CKD Stage 3b patient crafting Alkaline Elixir'),
(1, 5, 0.3, 35, 'CKD Stage 4 patient crafting Alkaline Elixir'),
(2, 3, 0.2, 25, 'CKD patient crafting Kidney Shield'),
(2, 5, 0.3, 35, 'CKD Stage 4 patient crafting Kidney Shield'),
(3, 7, 0.3, 40, 'Hemodialysis patient crafting Recovery Tonic'),
(3, 8, 0.3, 40, 'PD patient crafting Recovery Tonic'),
(13, 6, 0.3, 50, 'CKD Stage 5 patient crafting Legendary Kidney Elixir'),

-- Diabetes recipes get bonuses for diabetic patients
(4, 10, 0.2, 25, 'Type 1 patient crafting Glucose Stabilizer'),
(4, 11, 0.2, 25, 'Type 2 patient crafting Glucose Stabilizer'),
(5, 11, 0.25, 30, 'Type 2 patient crafting Insulin Sensitivity Brew'),
(14, 10, 0.3, 50, 'Type 1 patient crafting Legendary Sugar Slayer'),
(14, 11, 0.3, 50, 'Type 2 patient crafting Legendary Sugar Slayer'),

-- HTN recipes for HTN patients
(6, 14, 0.2, 25, 'HTN Stage 1 patient crafting DASH Remedy'),
(6, 15, 0.25, 30, 'HTN Stage 2 patient crafting DASH Remedy'),
(15, 15, 0.3, 50, 'HTN Stage 2 patient crafting Legendary Heart Shield'),

-- Other condition-specific bonuses
(9, 29, 0.3, 35, 'Anemia patient crafting Iron Forge Potion'),
(19, 18, 0.25, 30, 'Gout patient crafting Anti-Gout Remedy'),
(20, 26, 0.3, 35, 'Pregnant user crafting Prenatal Nourishment');

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT 'crafting_quality_tiers' AS tbl, COUNT(*) AS rows FROM crafting_quality_tiers
UNION ALL
SELECT 'crafting_recipes', COUNT(*) FROM crafting_recipes
UNION ALL
SELECT 'crafting_condition_bonuses', COUNT(*) FROM crafting_condition_bonuses
UNION ALL
SELECT 'user_crafting_inventory', COUNT(*) FROM user_crafting_inventory
UNION ALL
SELECT 'user_crafting_mastery', COUNT(*) FROM user_crafting_mastery
UNION ALL
SELECT 'crafting_materials', COUNT(*) FROM crafting_materials;
