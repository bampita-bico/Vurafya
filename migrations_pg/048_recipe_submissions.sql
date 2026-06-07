-- Migration 048: Recipe Submissions
-- Community-created recipes pending approval
-- Part of User Submission System (Phase 5)

-- ============================================================================
-- RECIPE_SUBMISSIONS TABLE
-- ============================================================================

CREATE TABLE recipe_submissions (
    id SERIAL PRIMARY KEY,

    -- Submitter information
    submitted_by_user_id INTEGER NOT NULL,
    submitter_name VARCHAR(100),
    submitter_email VARCHAR(200),

    -- Recipe basics
    recipe_name VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    cuisine_type VARCHAR(50),
    region VARCHAR(50),  -- East Africa / West Africa / etc.

    -- Recipe metadata
    default_servings INTEGER DEFAULT 4,
    prep_time_minutes INTEGER,
    cook_time_minutes INTEGER,
    total_time_minutes INTEGER,
    difficulty_level VARCHAR(20),  -- easy / medium / hard

    -- Health classifications
    is_ckd_friendly BOOLEAN DEFAULT FALSE,
    is_diabetic_friendly BOOLEAN DEFAULT FALSE,
    is_heart_healthy BOOLEAN DEFAULT FALSE,
    is_vegetarian BOOLEAN DEFAULT FALSE,
    is_vegan BOOLEAN DEFAULT FALSE,
    is_gluten_free BOOLEAN DEFAULT FALSE,

    -- Recipe content
    ingredients_json TEXT NOT NULL,  -- JSON array: [{"food_id": 9, "quantity_grams": 200, "description": "2 cups rice"}]
    cooking_steps_json TEXT NOT NULL,  -- JSON array: [{"step": 1, "instruction": "Wash rice...", "duration_min": 5}]
    cooking_method_id INTEGER,

    -- Nutritional information (calculated or user-provided)
    calories_per_serving DOUBLE PRECISION,
    protein_g_per_serving DOUBLE PRECISION,
    carbs_g_per_serving DOUBLE PRECISION,
    fat_g_per_serving DOUBLE PRECISION,
    fiber_g_per_serving DOUBLE PRECISION,
    sodium_mg_per_serving DOUBLE PRECISION,
    potassium_mg_per_serving DOUBLE PRECISION,

    -- Media
    recipe_photo_url VARCHAR(500),
    recipe_video_url VARCHAR(500),

    -- Submission context
    submission_reason TEXT,  -- Why share this recipe?
    family_recipe BOOLEAN DEFAULT FALSE,
    recipe_origin TEXT,  -- "My grandmother's recipe", "Traditional Ugandan dish"
    health_benefits TEXT,  -- What makes this recipe healthy?

    -- Review workflow
    status VARCHAR(20) DEFAULT 'pending',
    reviewed_by INTEGER,
    reviewed_at TIMESTAMP,
    approval_notes TEXT,
    rejection_reason TEXT,
    revision_requested_notes TEXT,

    -- Quality flags (set by reviewer)
    nutrition_verified BOOLEAN DEFAULT FALSE,
    instructions_clear BOOLEAN DEFAULT FALSE,
    ingredients_available BOOLEAN DEFAULT FALSE,
    culturally_appropriate BOOLEAN DEFAULT FALSE,

    -- Metadata
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (submitted_by_user_id) REFERENCES users(id),
    FOREIGN KEY (cooking_method_id) REFERENCES cooking_methods(id),
    FOREIGN KEY (reviewed_by) REFERENCES users(id),

    CHECK (status IN ('pending', 'under_review', 'approved', 'rejected', 'needs_revision')),
    CHECK (difficulty_level IN ('easy', 'medium', 'hard'))
);

CREATE INDEX idx_recipe_submissions_status ON recipe_submissions(status, submitted_at DESC);
CREATE INDEX idx_recipe_submissions_user ON recipe_submissions(submitted_by_user_id);


-- ============================================================================
-- EXAMPLE SEED DATA
-- ============================================================================

INSERT INTO recipe_submissions (
    submitted_by_user_id, submitter_name,
    recipe_name, description, cuisine_type, region,
    default_servings, prep_time_minutes, cook_time_minutes, total_time_minutes, difficulty_level,
    is_ckd_friendly, is_diabetic_friendly, is_vegetarian,
    ingredients_json, cooking_steps_json, cooking_method_id,
    recipe_photo_url,
    submission_reason, family_recipe, recipe_origin, health_benefits,
    status
) VALUES (
    101, 'Grace Wanjiru',
    'Low-Sodium Sukuma Wiki Stew', 'Traditional Kenyan collard greens stew adapted for CKD patients',
    'East African', 'Kenya',
    4, 10, 20, 30, 'easy',
    TRUE, TRUE, TRUE,
    '[{"food_id": 20, "quantity_grams": 500, "description": "1 bunch Sukuma Wiki (chopped)"}, {"food_id": 52, "quantity_grams": 200, "description": "2 medium tomatoes (diced)"}, {"food_id": 45, "quantity_grams": 50, "description": "1 small onion (chopped)"}, {"food_id": 60, "quantity_grams": 15, "description": "1 tbsp oil"}]',
    '[{"step": 1, "instruction": "Heat oil in pot over medium heat", "duration_min": 2}, {"step": 2, "instruction": "Add onions and sauté until translucent", "duration_min": 5}, {"step": 3, "instruction": "Add tomatoes and cook until soft", "duration_min": 5}, {"step": 4, "instruction": "Add Sukuma Wiki and stir. Add 1/4 cup water.", "duration_min": 3}, {"step": 5, "instruction": "Cover and simmer until greens are tender (10-15 minutes)", "duration_min": 12}]',
    9,
    'https://example.com/recipes/sukuma-wiki-stew.jpg',
    'I adapted my grandmother''s recipe to be CKD-friendly by removing salt and reducing tomatoes (lower potassium). This helped me manage my Stage 3 CKD while still enjoying traditional food.',
    TRUE,
    'My grandmother''s traditional recipe, modified for kidney disease',
    'Low sodium, moderate potassium, high fiber. Excellent for CKD patients who miss traditional foods.',
    'pending'
);