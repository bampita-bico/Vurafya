-- Migration 045: Expand Food Submissions
-- Community-powered database growth with admin review workflow
-- Part of User Submission System (Phase 5)

-- ============================================================================
-- DROP AND RECREATE FOOD_SUBMISSIONS TABLE
-- ============================================================================
-- Expand from basic structure to comprehensive submission system

DROP TABLE IF EXISTS food_submissions;

CREATE TABLE food_submissions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    -- Submitter information
    submitted_by_user_id INTEGER NOT NULL,
    submitter_name VARCHAR(100),  -- Display name
    submitter_email VARCHAR(200),

    -- Food identification
    food_name VARCHAR(200) NOT NULL,
    local_name VARCHAR(200),
    alternative_names TEXT,  -- JSON array: ["Matoke", "Cooking banana", "Plantain"]
    scientific_name VARCHAR(200),

    -- Classification
    food_category VARCHAR(100),
    food_subcategory VARCHAR(100),
    is_local BOOLEAN DEFAULT TRUE,
    region_code VARCHAR(10),  -- UG / KE / TZ / NG / etc.

    -- Nutritional data (per 100g)
    energy_kcal REAL,
    protein_g REAL,
    carbs_g REAL,
    fat_g REAL,
    fiber_g REAL,
    sugar_g REAL,

    -- Key micronutrients
    potassium_mg REAL,
    sodium_mg REAL,
    calcium_mg REAL,
    iron_mg REAL,
    magnesium_mg REAL,
    phosphorus_mg REAL,
    zinc_mg REAL,

    -- Vitamins
    vitamin_a_mcg REAL,
    vitamin_c_mg REAL,
    vitamin_d_mcg REAL,
    vitamin_e_mg REAL,
    folate_mcg REAL,
    vitamin_b12_mcg REAL,

    -- Clinical metrics
    glycemic_index REAL,
    glycemic_load REAL,
    pral_value REAL,  -- Renal acid load

    -- Data source & quality
    data_source VARCHAR(200),  -- "Personal measurement" / "Food label" / "FAO database" / "Research paper"
    source_url VARCHAR(500),
    data_quality_self_rating INTEGER,  -- 1-5 (user's confidence in their data)

    -- Supporting evidence
    has_food_label_photo BOOLEAN DEFAULT FALSE,
    food_label_photo_url VARCHAR(500),
    has_measurement_proof BOOLEAN DEFAULT FALSE,
    measurement_proof_url VARCHAR(500),

    -- Submission reason
    submission_reason TEXT,  -- Why is this food important? Why should it be added?
    cultural_significance TEXT,  -- Cultural/traditional context
    health_benefits TEXT,  -- Known health properties

    -- Review workflow
    status VARCHAR(20) DEFAULT 'pending',  -- pending / under_review / approved / rejected / needs_revision
    reviewed_by INTEGER,  -- Admin/nutritionist who reviewed
    reviewed_at TIMESTAMP,
    rejection_reason TEXT,
    revision_requested_notes TEXT,

    -- Metadata
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (submitted_by_user_id) REFERENCES users(id),
    FOREIGN KEY (reviewed_by) REFERENCES users(id),

    CHECK (status IN ('pending', 'under_review', 'approved', 'rejected', 'needs_revision')),
    CHECK (data_quality_self_rating BETWEEN 1 AND 5)
);

CREATE INDEX idx_food_submissions_status ON food_submissions(status, submitted_at DESC);
CREATE INDEX idx_food_submissions_user ON food_submissions(submitted_by_user_id, submitted_at DESC);
CREATE INDEX idx_food_submissions_region ON food_submissions(region_code, status);


-- ============================================================================
-- EXAMPLE SEED DATA
-- ============================================================================

INSERT OR IGNORE INTO food_submissions (
    submitted_by_user_id, submitter_name, submitter_email,
    food_name, local_name, alternative_names, food_category, region_code, is_local,
    energy_kcal, protein_g, carbs_g, fat_g, fiber_g,
    potassium_mg, sodium_mg, iron_mg,
    glycemic_index, data_source, data_quality_self_rating,
    submission_reason, cultural_significance,
    status
) VALUES (
    123, 'Sarah Nakato', 'sarah@example.com',
    'Matembele', 'Sweet Potato Leaves', '["Matembele", "Sukuma wiki ya viazi", "SP leaves"]',
    'Leafy Vegetables', 'UG', TRUE,
    35, 3.2, 6.8, 0.5, 2.1,
    410, 8, 2.8,
    15, 'Personal farm measurement + local nutrition lab',
    4,
    'Matembele is a staple vegetable in Uganda that is missing from the database. It is affordable, locally grown, and very nutritious.',
    'Traditionally eaten with posho or matoke. Very popular in rural Uganda. Rich in iron, helps prevent anemia in pregnant women.',
    'pending'
);