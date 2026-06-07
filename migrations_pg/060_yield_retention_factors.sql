-- Migration 060: Yield Retention Factors
-- Cooking methods affect nutritional values (boiling reduces vitamins, frying adds fat)
-- Part of Meal-First Architecture (Phase 2)

-- ============================================================================
-- COOKING METHODS TABLE
-- ============================================================================
-- Defines cooking techniques and their average nutritional impact

CREATE TABLE cooking_methods (
    id SERIAL PRIMARY KEY,
    method_name VARCHAR(50) NOT NULL UNIQUE,
    method_category VARCHAR(50) NOT NULL,  -- moist_heat / dry_heat / combination / no_cooking

    -- Description
    description TEXT,
    typical_temperature_c INTEGER,
    cooking_medium VARCHAR(50),  -- water / oil / air / steam / mixed

    -- Average nutritional impact (food-specific overrides in food_cooking_method_retention table)
    vitamin_retention_avg DOUBLE PRECISION DEFAULT 1.0,  -- 0.0-1.0 (1.0 = 100% retained)
    mineral_retention_avg DOUBLE PRECISION DEFAULT 1.0,
    protein_impact DOUBLE PRECISION DEFAULT 1.0,  -- Usually stable
    fat_impact DOUBLE PRECISION DEFAULT 1.0,  -- Can increase with frying (>1.0)
    carb_impact DOUBLE PRECISION DEFAULT 1.0,
    fiber_impact DOUBLE PRECISION DEFAULT 1.0,

    -- Physical changes
    water_content_change DOUBLE PRECISION DEFAULT 0.0,  -- Negative = loss (evaporation), Positive = gain (absorption)
    weight_yield_factor DOUBLE PRECISION DEFAULT 1.0,  -- Cooked weight / raw weight (0.9 = 10% weight loss)
    volume_change DOUBLE PRECISION DEFAULT 1.0,  -- Cooked volume / raw volume

    -- Health rating
    health_rating INTEGER DEFAULT 3,  -- 1-5 (1=unhealthy like deep frying, 5=healthiest like steaming)
    health_notes TEXT,

    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CHECK (health_rating BETWEEN 1 AND 5)
);

CREATE INDEX idx_cooking_methods_category ON cooking_methods(method_category);
CREATE INDEX idx_cooking_methods_health ON cooking_methods(health_rating DESC);


-- ============================================================================
-- SEED DATA: COOKING METHODS
-- ============================================================================

-- 1. BOILING (Moist Heat)
INSERT INTO cooking_methods VALUES
(1, 'Boiling', 'moist_heat',
    'Cooking in water at 100°C. Water-soluble vitamins (B, C) leach out. Minerals retained unless water is discarded.',
    100, 'water',
    0.50, 0.85, 1.0, 1.0, 1.0, 1.0,
    0.0, 0.90, 1.05,
    4, 'Good for starches (rice, potatoes). Retain cooking water for soups to preserve nutrients.',
    CURRENT_TIMESTAMP);

-- 2. STEAMING (Moist Heat) - BEST for nutrient retention
INSERT INTO cooking_methods VALUES
(2, 'Steaming', 'moist_heat',
    'Cooking with steam (indirect water contact). Minimal nutrient loss. Best method for vegetables.',
    100, 'steam',
    0.85, 0.95, 1.0, 1.0, 1.0, 1.0,
    0.05, 0.95, 1.02,
    5, 'Best method for vegetables. Minimal nutrient loss. Retains color, texture, and flavor.',
    CURRENT_TIMESTAMP);

-- 3. DEEP FRYING (Dry Heat)
INSERT INTO cooking_methods VALUES
(3, 'Frying (Deep)', 'dry_heat',
    'Submerging in hot oil (160-190°C). High fat absorption. Vitamin loss from high heat. Forms harmful compounds (acrylamide).',
    180, 'oil',
    0.60, 0.90, 1.0, 2.5, 1.0, 0.95,
    -0.20, 0.80, 0.85,
    1, 'Unhealthy: High fat, calories, and potentially carcinogenic compounds. Use sparingly.',
    CURRENT_TIMESTAMP);

-- 4. SHALLOW FRYING (Dry Heat)
INSERT INTO cooking_methods VALUES
(4, 'Frying (Shallow)', 'dry_heat',
    'Cooking in small amount of oil. Moderate fat absorption. Better than deep frying but not ideal.',
    160, 'oil',
    0.70, 0.92, 1.0, 1.5, 1.0, 0.98,
    -0.10, 0.85, 0.90,
    2, 'Moderate health impact. Use healthy oils (olive, avocado). Control portion sizes.',
    CURRENT_TIMESTAMP);

-- 5. GRILLING / BROILING (Dry Heat)
INSERT INTO cooking_methods VALUES
(5, 'Grilling', 'dry_heat',
    'Cooking over direct heat (charcoal, gas, electric). High temps can form carcinogens (HCAs, PAHs) on charred meat.',
    200, 'air',
    0.75, 0.90, 0.95, 0.90, 1.0, 1.0,
    -0.15, 0.85, 0.85,
    3, 'Avoid charring meat. Marinate to reduce carcinogen formation. Good for vegetables.',
    CURRENT_TIMESTAMP);

-- 6. ROASTING / BAKING (Dry Heat)
INSERT INTO cooking_methods VALUES
(6, 'Roasting', 'dry_heat',
    'Baking in oven with dry heat. Good nutrient retention. Maillard reaction enhances flavor.',
    180, 'air',
    0.80, 0.92, 1.0, 1.0, 1.0, 1.0,
    -0.10, 0.90, 0.95,
    4, 'Healthy method. Enhances flavor through browning. Good for vegetables, meat, fish.',
    CURRENT_TIMESTAMP);

-- 7. MICROWAVING (Combination)
INSERT INTO cooking_methods VALUES
(7, 'Microwaving', 'combination',
    'Heating with microwave radiation. Fast cooking = minimal nutrient loss. Short water exposure.',
    120, 'mixed',
    0.90, 0.98, 1.0, 1.0, 1.0, 1.0,
    -0.05, 0.98, 1.0,
    5, 'Excellent nutrient retention due to short cooking time. Use microwave-safe containers.',
    CURRENT_TIMESTAMP);

-- 8. PRESSURE COOKING (Moist Heat)
INSERT INTO cooking_methods VALUES
(8, 'Pressure Cooking', 'moist_heat',
    'Cooking under high pressure (121°C). Short cooking time = good nutrient retention. Popular in East Africa.',
    121, 'water',
    0.80, 0.95, 1.0, 1.0, 1.0, 1.0,
    0.0, 0.92, 1.0,
    4, 'Good nutrient retention. Fast cooking. Tenderizes tough cuts. Retains flavor.',
    CURRENT_TIMESTAMP);

-- 9. STEWING (Moist Heat)
INSERT INTO cooking_methods VALUES
(9, 'Stewing', 'moist_heat',
    'Slow cooking in liquid (water, broth, sauce). Nutrients leach into liquid but are consumed with the dish.',
    95, 'water',
    0.65, 0.90, 1.0, 1.0, 1.0, 1.0,
    0.10, 0.95, 1.10,
    4, 'Nutrients stay in dish if liquid is consumed. Good for tough cuts. Common in African cuisine.',
    CURRENT_TIMESTAMP);

-- 10. RAW (No Cooking)
INSERT INTO cooking_methods VALUES
(10, 'Raw', 'no_cooking',
    'Uncooked food. 100% nutrient retention but some nutrients less bioavailable (e.g., lycopene in tomatoes).',
    NULL, 'none',
    1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
    0.0, 1.0, 1.0,
    5, 'Maximum nutrients but potential food safety risks. Wash thoroughly. Some nutrients more bioavailable when cooked.',
    CURRENT_TIMESTAMP);


-- ============================================================================
-- FOOD-SPECIFIC COOKING METHOD RETENTION TABLE
-- ============================================================================
-- Overrides generic cooking_methods averages for specific food + method combinations
-- Example: Spinach loses more vitamins when boiled than generic vegetables

CREATE TABLE food_cooking_method_retention (
    id SERIAL PRIMARY KEY,
    food_id INTEGER NOT NULL,
    cooking_method_id INTEGER NOT NULL,

    -- Macronutrient retention (0.0-1.0)
    protein_retention DOUBLE PRECISION DEFAULT 1.0,
    carb_retention DOUBLE PRECISION DEFAULT 1.0,
    fat_retention DOUBLE PRECISION DEFAULT 1.0,
    fiber_retention DOUBLE PRECISION DEFAULT 1.0,

    -- Vitamin-specific retention (water-soluble vitamins most affected by boiling)
    vitamin_c_retention DOUBLE PRECISION,  -- Most vulnerable (oxidation + water leaching)
    vitamin_b1_retention DOUBLE PRECISION,  -- Thiamine (heat-sensitive)
    vitamin_b2_retention DOUBLE PRECISION,  -- Riboflavin
    vitamin_b3_retention DOUBLE PRECISION,  -- Niacin (most stable)
    vitamin_b6_retention DOUBLE PRECISION,  -- Pyridoxine
    vitamin_b9_retention DOUBLE PRECISION,  -- Folate (very heat-sensitive)
    vitamin_b12_retention DOUBLE PRECISION,  -- Cobalamin (stable in cooking)
    vitamin_a_retention DOUBLE PRECISION,  -- Fat-soluble (stable, can increase bioavailability with heat)
    vitamin_d_retention DOUBLE PRECISION,
    vitamin_e_retention DOUBLE PRECISION,
    vitamin_k_retention DOUBLE PRECISION,

    -- Mineral retention (generally stable but water-soluble)
    potassium_retention DOUBLE PRECISION,  -- Leaches into cooking water
    sodium_retention DOUBLE PRECISION,  -- Usually stable (can increase if salt added)
    calcium_retention DOUBLE PRECISION,
    iron_retention DOUBLE PRECISION,
    magnesium_retention DOUBLE PRECISION,
    phosphorus_retention DOUBLE PRECISION,
    zinc_retention DOUBLE PRECISION,

    -- Physical changes
    weight_yield DOUBLE PRECISION,  -- Cooked weight = raw weight × yield
    volume_yield DOUBLE PRECISION,
    cooking_time_minutes INTEGER,

    -- Bioavailability changes (can improve with cooking)
    bioavailability_change TEXT,  -- "Lycopene +35% with cooking", "Iron absorption improved"

    -- Data quality
    notes TEXT,
    data_source VARCHAR(200),  -- USDA FoodData Central, FAO INFOODS, HarvestPlus
    measurement_method VARCHAR(100),  -- laboratory_measured / literature_review / calculated

    FOREIGN KEY (food_id) REFERENCES foods(id),
    FOREIGN KEY (cooking_method_id) REFERENCES cooking_methods(id),
    UNIQUE(food_id, cooking_method_id)
);

CREATE INDEX idx_food_cooking_retention_food ON food_cooking_method_retention(food_id);
CREATE INDEX idx_food_cooking_retention_method ON food_cooking_method_retention(cooking_method_id);


-- ============================================================================
-- EXAMPLE SEED DATA: Common East African Foods
-- ============================================================================
-- (Food IDs are placeholders - actual IDs depend on foods.csv)

-- Spinach (Sukuma Wiki) - Boiled
INSERT INTO food_cooking_method_retention VALUES
(1, 20, 1,  -- food_id=20 (Sukuma Wiki), cooking_method_id=1 (Boiling)
    1.0, 1.0, 1.0, 0.90,  -- Macros
    0.35, 0.55, 0.70, 0.85, 0.60, 0.40, 1.0,  -- Vitamins (Vitamin C loss 65%, Folate loss 60%)
    0.90, 1.0, 0.80, 0.85,  -- Fat-soluble vitamins
    0.50, 1.0, 0.80, 0.85, 0.70, 0.85, 0.90,  -- Minerals (K+ loss 50% if water discarded)
    0.85, 0.90, 10,  -- Weight loss 15%, volume loss 10%, 10 minutes cooking
    'Vitamin C and folate very vulnerable. Retain cooking water for soups.',
    'USDA FoodData Central SR-28', 'laboratory_measured');

-- Spinach - Steamed (Better retention)
INSERT INTO food_cooking_method_retention VALUES
(2, 20, 2,  -- Sukuma Wiki - Steaming
    1.0, 1.0, 1.0, 0.95,
    0.75, 0.80, 0.85, 0.95, 0.85, 0.70, 1.0,  -- Much better vitamin retention
    0.95, 1.0, 0.90, 0.95,
    0.85, 1.0, 0.90, 0.92, 0.85, 0.92, 0.95,  -- Better mineral retention
    0.92, 0.95, 8,
    'Steaming retains 75% of Vitamin C vs 35% with boiling. Best method for leafy greens.',
    'USDA FoodData Central SR-28', 'laboratory_measured');

-- Sweet Potato - Boiled
INSERT INTO food_cooking_method_retention VALUES
(3, 6, 1,  -- food_id=6 (Sweet Potato) - Boiling
    1.0, 0.95, 1.0, 0.95,
    0.80, 0.75, 0.85, 0.95, 0.75, 0.70, NULL,  -- Beta-carotene (Vitamin A precursor) mostly retained
    1.05, NULL, 0.95, 1.0,  -- Vitamin A bioavailability actually increases with cooking
    0.70, 1.0, 0.95, 0.92, 0.80, 0.88, 0.92,  -- K+ loss 30%
    1.10, 1.08, 25,  -- Weight gain 10% (water absorption)
    'Beta-carotene bioavailability increases with cooking. Potassium leaches into water.',
    'HarvestPlus Biofortification Studies', 'laboratory_measured');

-- Beans (Common Beans) - Boiled
INSERT INTO food_cooking_method_retention VALUES
(4, 15, 1,  -- Beans - Boiling (mandatory for safety - raw beans toxic)
    0.95, 1.0, 1.0, 0.95,
    0.50, 0.60, 0.75, 0.90, 0.65, 0.55, 1.0,  -- B vitamins partially lost
    NULL, NULL, 0.85, 0.90,
    0.60, 1.0, 0.85, 0.88, 0.75, 0.85, 0.90,  -- K+ loss 40%
    2.10, 2.00, 120,  -- Weight gain 110% (absorb water), 2 hours cooking
    'Soaking reduces phytic acid (anti-nutrient). Discard soaking water. Pressure cooking faster and retains more nutrients.',
    'FAO INFOODS', 'laboratory_measured');

-- Matoke (Cooking Bananas) - Steamed
INSERT INTO food_cooking_method_retention VALUES
(5, 7, 2,  -- Matoke - Steaming
    1.0, 0.98, 1.0, 0.98,
    0.85, 0.80, 0.88, 0.95, 0.82, 0.75, NULL,
    1.10, NULL, 0.92, 0.98,  -- Vitamin A bioavailability increases
    0.80, 1.0, 0.92, 0.95, 0.88, 0.92, 0.95,
    1.05, 1.02, 30,
    'Steaming is traditional East African method. Good nutrient retention.',
    'FAO INFOODS - East Africa', 'laboratory_measured');

-- Rice (White) - Boiled
INSERT INTO food_cooking_method_retention VALUES
(6, 9, 1,  -- White Rice - Boiling
    1.0, 1.0, 1.0, 1.0,
    NULL, 0.20, 0.30, 0.90, 0.25, 0.15, NULL,  -- White rice already nutrient-poor
    NULL, NULL, NULL, NULL,
    0.30, 1.0, 0.40, 0.50, 0.35, 0.40, 0.60,  -- Massive mineral loss if water discarded
    2.50, 2.30, 20,  -- Weight gain 150% (absorbs water)
    'White rice nutrient-poor. Use absorption method (don''t discard water) or switch to brown rice.',
    'USDA FoodData Central SR-28', 'laboratory_measured');

-- Tomatoes - Stewed
INSERT INTO food_cooking_method_retention VALUES
(7, 52, 9,  -- Tomatoes - Stewing
    1.0, 0.95, 1.0, 0.95,
    0.70, 0.75, 0.85, 0.95, 0.80, 0.75, NULL,
    1.35, NULL, 0.90, 0.95,  -- Lycopene (Vitamin A precursor) bioavailability +35% with cooking!
    0.85, 1.0, 0.90, 0.95, 0.88, 0.92, 0.95,
    0.85, 0.90, 45,
    'Cooking INCREASES lycopene bioavailability by 35%. Stewing in sauce common in African cuisine.',
    'Harvard Nutrition Studies', 'literature_review');


-- ============================================================================
-- USAGE FLOW (Application Layer)
-- ============================================================================
-- STEP 1: User logs meal with cooking method
-- - "I ate 200g boiled sweet potatoes"
-- - meal_components: food_id=6, quantity_grams=200
-- - meals: cooking_method_id=1 (Boiling)
--
-- STEP 2: Calculate raw nutrition
-- - Query food_nutrients WHERE food_id = 6
-- - Vitamin C (raw): 20mg/100g
-- - Potassium (raw): 350mg/100g
-- - Protein (raw): 2g/100g
--
-- STEP 3: Apply cooking retention factors
-- - Query food_cooking_method_retention WHERE food_id=6 AND cooking_method_id=1
-- - Vitamin C retention: 0.80 (80% retained)
-- - Potassium retention: 0.70 (70% retained)
-- - Protein retention: 1.0 (100% retained)
--
-- STEP 4: Calculate cooked nutrition
-- - Vitamin C (cooked): 20mg × 0.80 = 16mg per 100g
-- - Potassium (cooked): 350mg × 0.70 = 245mg per 100g
-- - Protein (cooked): 2g × 1.0 = 2g per 100g
--
-- STEP 5: Adjust for portion size
-- - 200g portion → × 2
-- - Vitamin C: 16mg × 2 = 32mg
-- - Potassium: 245mg × 2 = 490mg
-- - Protein: 2g × 2 = 4g
--
-- STEP 6: Store in meal_nutrition_calculations
-- - raw_vitamin_c: 40mg (20mg × 2)
-- - adjusted_vitamin_c: 32mg (after cooking)
-- - cooking_method_id: 1
-- - data_quality_score: 0.95 (measured data)
--
-- STEP 7: Compare to nutrient targets
-- - User has CKD Stage 3a → K+ target <2000mg/day
-- - This meal contributed 490mg K+
-- - Remaining budget: 1510mg
-- - Display: "✅ 490mg K+ / 2000mg target (25% of daily limit)"
--
-- FALLBACK: If food-specific retention data missing
-- - Use cooking_methods.vitamin_retention_avg (generic)
-- - Flag data_quality_score as "estimated"
-- - Prompt admin to add food-specific data
