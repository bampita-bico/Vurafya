-- Migration 062: Recipe System with Portions & Variations
-- Enhances recipes table with nutrition, difficulty, health ratings
-- Adds recipe variations (different cooking methods for same recipe)
-- Part of Meal-First Architecture (Phase 2)

-- ============================================================================
-- ENHANCE RECIPES TABLE
-- ============================================================================
-- Add columns for better recipe management and user experience

ALTER TABLE recipes ADD COLUMN default_servings INTEGER DEFAULT 4;
ALTER TABLE recipes ADD COLUMN calories_per_serving REAL;
ALTER TABLE recipes ADD COLUMN prep_time_minutes INTEGER;
ALTER TABLE recipes ADD COLUMN cook_time_minutes INTEGER;
ALTER TABLE recipes ADD COLUMN total_time_minutes INTEGER;  -- prep + cook
ALTER TABLE recipes ADD COLUMN difficulty_level VARCHAR(20) DEFAULT 'medium';
ALTER TABLE recipes ADD COLUMN cuisine_type VARCHAR(50);
ALTER TABLE recipes ADD COLUMN region VARCHAR(50);  -- East Africa / West Africa / North Africa / etc.

-- Health ratings (condition-specific)
ALTER TABLE recipes ADD COLUMN is_ckd_friendly BOOLEAN DEFAULT FALSE;
ALTER TABLE recipes ADD COLUMN is_diabetic_friendly BOOLEAN DEFAULT FALSE;
ALTER TABLE recipes ADD COLUMN is_heart_healthy BOOLEAN DEFAULT FALSE;
ALTER TABLE recipes ADD COLUMN is_vegetarian BOOLEAN DEFAULT FALSE;
ALTER TABLE recipes ADD COLUMN is_vegan BOOLEAN DEFAULT FALSE;
ALTER TABLE recipes ADD COLUMN is_gluten_free BOOLEAN DEFAULT FALSE;

-- Nutrition summary per serving (calculated from recipe_ingredients)
ALTER TABLE recipes ADD COLUMN protein_g_per_serving REAL;
ALTER TABLE recipes ADD COLUMN carbs_g_per_serving REAL;
ALTER TABLE recipes ADD COLUMN fat_g_per_serving REAL;
ALTER TABLE recipes ADD COLUMN fiber_g_per_serving REAL;
ALTER TABLE recipes ADD COLUMN sodium_mg_per_serving REAL;
ALTER TABLE recipes ADD COLUMN potassium_mg_per_serving REAL;

-- Metadata
ALTER TABLE recipes ADD COLUMN created_by_user_id INTEGER;
ALTER TABLE recipes ADD COLUMN is_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE recipes ADD COLUMN verification_date DATE;
ALTER TABLE recipes ADD COLUMN view_count INTEGER DEFAULT 0;
ALTER TABLE recipes ADD COLUMN favorite_count INTEGER DEFAULT 0;

-- Add check constraint
-- ALTER TABLE recipes ADD CHECK (difficulty_level IN ('easy', 'medium', 'hard', 'expert'));

-- Create indexes
CREATE INDEX idx_recipes_difficulty ON recipes(difficulty_level);
CREATE INDEX idx_recipes_health ON recipes(is_ckd_friendly, is_diabetic_friendly, is_heart_healthy);
CREATE INDEX idx_recipes_cuisine ON recipes(cuisine_type, region);
CREATE INDEX idx_recipes_verified ON recipes(is_verified, created_at DESC);


-- ============================================================================
-- RECIPE VARIATIONS TABLE
-- ============================================================================
-- Different cooking methods for the same base recipe
-- Example: "Sukuma Wiki" can be steamed, boiled, or stir-fried

CREATE TABLE recipe_variations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    base_recipe_id INTEGER NOT NULL,
    variation_name VARCHAR(100) NOT NULL,
    cooking_method_id INTEGER NOT NULL,

    -- Nutritional differences from base recipe (percentage adjustments)
    calories_adjustment_pct REAL DEFAULT 0.0,  -- +/- percentage
    fat_adjustment_pct REAL DEFAULT 0.0,
    sodium_adjustment_pct REAL DEFAULT 0.0,
    fiber_adjustment_pct REAL DEFAULT 0.0,

    -- Time adjustments
    prep_time_adjustment_min INTEGER DEFAULT 0,
    cook_time_adjustment_min INTEGER DEFAULT 0,

    -- Health rating comparison to base
    health_rating INTEGER,  -- 1-5 (5=healthiest)
    health_comparison VARCHAR(50),  -- healthier / similar / less_healthy

    -- Description
    variation_notes TEXT,
    why_choose_this TEXT,  -- "Choose steaming to preserve vitamins", "Choose stir-frying for better flavor"

    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,

    FOREIGN KEY (base_recipe_id) REFERENCES recipes(id),
    FOREIGN KEY (cooking_method_id) REFERENCES cooking_methods(id),

    CHECK (health_rating BETWEEN 1 AND 5),
    UNIQUE(base_recipe_id, cooking_method_id)
);

CREATE INDEX idx_recipe_variations_base ON recipe_variations(base_recipe_id, is_active);
CREATE INDEX idx_recipe_variations_method ON recipe_variations(cooking_method_id);


-- ============================================================================
-- RECIPE COOKING STEPS TABLE
-- ============================================================================
-- Detailed step-by-step instructions (previously stored as TEXT in recipes.instructions)

CREATE TABLE recipe_cooking_steps (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    recipe_id INTEGER NOT NULL,
    step_number INTEGER NOT NULL,

    -- Step details
    step_title VARCHAR(100),  -- "Prepare vegetables", "Cook rice", "Simmer sauce"
    step_instruction TEXT NOT NULL,
    duration_minutes INTEGER,  -- How long this step takes

    -- Media
    image_url VARCHAR(500),
    video_url VARCHAR(500),

    -- Tips
    chef_tip TEXT,  -- Pro tips for this step
    common_mistake TEXT,  -- What to avoid

    FOREIGN KEY (recipe_id) REFERENCES recipes(id),
    UNIQUE(recipe_id, step_number)
);

CREATE INDEX idx_cooking_steps_recipe ON recipe_cooking_steps(recipe_id, step_number);


-- ============================================================================
-- RECIPE RATINGS & REVIEWS TABLE
-- ============================================================================
-- User feedback on recipes

CREATE TABLE recipe_reviews (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    recipe_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,

    -- Rating (1-5 stars)
    overall_rating INTEGER NOT NULL,
    taste_rating INTEGER,
    difficulty_rating INTEGER,  -- Was it as easy/hard as expected?
    nutrition_rating INTEGER,  -- Did it help health goals?

    -- Review
    review_title VARCHAR(100),
    review_text TEXT,

    -- User experience
    modifications_made TEXT,  -- "I used olive oil instead of vegetable oil"
    would_make_again BOOLEAN,

    -- Helpfulness (other users vote)
    helpful_count INTEGER DEFAULT 0,
    not_helpful_count INTEGER DEFAULT 0,

    -- Moderation
    is_approved BOOLEAN DEFAULT FALSE,
    is_flagged BOOLEAN DEFAULT FALSE,
    flag_reason TEXT,

    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,

    FOREIGN KEY (recipe_id) REFERENCES recipes(id),
    FOREIGN KEY (user_id) REFERENCES users(id),

    CHECK (overall_rating BETWEEN 1 AND 5),
    UNIQUE(recipe_id, user_id)  -- One review per user per recipe
);

CREATE INDEX idx_recipe_reviews_recipe ON recipe_reviews(recipe_id, is_approved DESC);
CREATE INDEX idx_recipe_reviews_user ON recipe_reviews(user_id, created_at DESC);
CREATE INDEX idx_recipe_reviews_rating ON recipe_reviews(overall_rating DESC, created_at DESC);


-- ============================================================================
-- RECIPE FAVORITES TABLE
-- ============================================================================
-- Users can favorite recipes for quick access

CREATE TABLE recipe_favorites (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    recipe_id INTEGER NOT NULL,

    -- Organization
    folder VARCHAR(50),  -- breakfast / lunch / dinner / snacks / special_occasions
    notes TEXT,  -- Personal notes: "Kids love this", "Good for meal prep"

    -- Metadata
    favorited_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_cooked_at TIMESTAMP,
    times_cooked INTEGER DEFAULT 0,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (recipe_id) REFERENCES recipes(id),

    UNIQUE(user_id, recipe_id)
);

CREATE INDEX idx_favorites_user ON recipe_favorites(user_id, folder, favorited_at DESC);
CREATE INDEX idx_favorites_recipe ON recipe_favorites(recipe_id, favorited_at DESC);


-- ============================================================================
-- RECIPE TAGS TABLE (Many-to-Many)
-- ============================================================================
-- Flexible tagging system for recipes

CREATE TABLE recipe_tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tag_name VARCHAR(50) NOT NULL UNIQUE,
    tag_category VARCHAR(50),  -- meal_type / cuisine / diet / health / occasion / season

    -- Usage stats
    usage_count INTEGER DEFAULT 0,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE recipe_tag_assignments (
    recipe_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,

    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (recipe_id) REFERENCES recipes(id),
    FOREIGN KEY (tag_id) REFERENCES recipe_tags(id),

    PRIMARY KEY (recipe_id, tag_id)
);

CREATE INDEX idx_tag_assignments_recipe ON recipe_tag_assignments(recipe_id);
CREATE INDEX idx_tag_assignments_tag ON recipe_tag_assignments(tag_id);


-- ============================================================================
-- SEED DATA: Recipe Tags
-- ============================================================================

-- Meal Type Tags
INSERT OR IGNORE INTO recipe_tags (tag_name, tag_category) VALUES
('Breakfast', 'meal_type'),
('Lunch', 'meal_type'),
('Dinner', 'meal_type'),
('Snack', 'meal_type'),
('Dessert', 'meal_type');

-- Cuisine Tags
INSERT OR IGNORE INTO recipe_tags (tag_name, tag_category) VALUES
('East African', 'cuisine'),
('West African', 'cuisine'),
('North African', 'cuisine'),
('Southern African', 'cuisine'),
('Ugandan', 'cuisine'),
('Kenyan', 'cuisine'),
('Tanzanian', 'cuisine'),
('Nigerian', 'cuisine'),
('Ethiopian', 'cuisine');

-- Diet Tags
INSERT OR IGNORE INTO recipe_tags (tag_name, tag_category) VALUES
('Vegetarian', 'diet'),
('Vegan', 'diet'),
('Gluten-Free', 'diet'),
('Dairy-Free', 'diet'),
('Low-Carb', 'diet'),
('High-Protein', 'diet'),
('Low-Fat', 'diet');

-- Health Tags
INSERT OR IGNORE INTO recipe_tags (tag_name, tag_category) VALUES
('CKD-Friendly', 'health'),
('Diabetic-Friendly', 'health'),
('Heart-Healthy', 'health'),
('Low-Sodium', 'health'),
('High-Fiber', 'health'),
('Low-Glycemic', 'health');

-- Occasion Tags
INSERT OR IGNORE INTO recipe_tags (tag_name, tag_category) VALUES
('Quick & Easy', 'occasion'),
('Meal Prep', 'occasion'),
('One-Pot', 'occasion'),
('Budget-Friendly', 'occasion'),
('Special Occasion', 'occasion'),
('Kid-Friendly', 'occasion');

-- Season Tags (for seasonal ingredients)
INSERT OR IGNORE INTO recipe_tags (tag_name, tag_category) VALUES
('Dry Season', 'season'),
('Wet Season', 'season'),
('Year-Round', 'season');


-- ============================================================================
-- EXAMPLE USAGE: Recipe with Variations
-- ============================================================================

-- BASE RECIPE: Sukuma Wiki (Steamed) - Healthiest version
-- INSERT OR IGNORE INTO recipes (name, description, default_servings, prep_time_minutes, cook_time_minutes, difficulty_level, cuisine_type, region, is_ckd_friendly, is_diabetic_friendly, is_heart_healthy, is_vegetarian, is_vegan)
-- VALUES
-- ('Steamed Sukuma Wiki', 'Traditional East African collard greens, steamed to preserve nutrients', 4, 10, 8, 'easy', 'East African', 'East Africa', TRUE, TRUE, TRUE, TRUE, TRUE);

-- VARIATION 1: Boiled Sukuma Wiki
-- INSERT OR IGNORE INTO recipe_variations (base_recipe_id, variation_name, cooking_method_id, calories_adjustment_pct, health_rating, health_comparison, variation_notes, why_choose_this)
-- VALUES
-- (recipe_id, 'Boiled Sukuma Wiki', 1, 0.0, 3, 'less_healthy', 'Boiling causes 50% vitamin C loss. Retain cooking water for soup.', 'Choose if you want to use cooking water in soup or stew.');

-- VARIATION 2: Stir-Fried Sukuma Wiki (with oil)
-- INSERT OR IGNORE INTO recipe_variations (base_recipe_id, variation_name, cooking_method_id, calories_adjustment_pct, fat_adjustment_pct, health_rating, health_comparison, variation_notes, why_choose_this)
-- VALUES
-- (recipe_id, 'Stir-Fried Sukuma Wiki', 4, +15.0, +200.0, 2, 'less_healthy', 'Stir-frying adds oil (extra calories and fat) but enhances flavor.', 'Choose for better taste, but use healthy oil (olive, avocado) and control portion.');


-- ============================================================================
-- PORTION FLEXIBILITY
-- ============================================================================

-- When user logs recipe-based meal with non-standard portion:
-- INSERT OR IGNORE INTO meals (user_id, meal_source, recipe_id, portion_size_pct, meal_time)
-- VALUES (123, 'recipe', 45, 75.0, '2026-04-12 13:00:00');
-- → 75% of standard serving (3/4 portion)
--
-- Nutrition calculation:
-- calories_consumed = recipe.calories_per_serving × (portion_size_pct / 100)
-- protein_consumed = recipe.protein_g_per_serving × 0.75
-- etc.

-- If user ate "1.5 servings":
-- portion_size_pct = 150.0


-- ============================================================================
-- RECIPE SEARCH & FILTERING
-- ============================================================================

-- Find CKD-friendly, easy, East African breakfast recipes:
-- SELECT r.* FROM recipes r
-- JOIN recipe_tag_assignments rta ON r.id = rta.recipe_id
-- JOIN recipe_tags rt ON rta.tag_id = rt.id
-- WHERE r.is_ckd_friendly = TRUE
--   AND r.difficulty_level = 'easy'
--   AND r.region = 'East Africa'
--   AND rt.tag_name = 'Breakfast'
--   AND r.is_verified = TRUE
-- ORDER BY r.favorite_count DESC, r.view_count DESC
-- LIMIT 20;

-- Find recipes with <500mg sodium per serving:
-- SELECT * FROM recipes
-- WHERE sodium_mg_per_serving < 500
--   AND is_verified = TRUE
-- ORDER BY overall_rating DESC;


-- ============================================================================
-- CLINICAL DECISION INTEGRATION
-- ============================================================================

-- When recommending recipes based on health_rules:
-- User has CKD + high K+ (5.2 mEq/L)
-- → Query: SELECT * FROM recipes WHERE is_ckd_friendly = TRUE AND potassium_mg_per_serving < 500
-- → Filter variations: Prefer steamed over boiled (better nutrient retention)
-- → Display: "🥬 Steamed Sukuma Wiki - CKD-Friendly (380mg K+ per serving)"
