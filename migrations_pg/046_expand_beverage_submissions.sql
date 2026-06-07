-- Migration 046: Expand Beverage Submissions
-- Community-powered beverage database growth
-- Part of User Submission System (Phase 5)

-- ============================================================================
-- DROP AND RECREATE BEVERAGE_SUBMISSIONS TABLE
-- ============================================================================

DROP TABLE IF EXISTS beverage_submissions;

CREATE TABLE beverage_submissions (
    id SERIAL PRIMARY KEY,

    -- Submitter information
    submitted_by_user_id INTEGER NOT NULL,
    submitter_name VARCHAR(100),
    submitter_email VARCHAR(200),

    -- Beverage identification
    beverage_name VARCHAR(200) NOT NULL,
    local_name VARCHAR(200),
    alternative_names TEXT,  -- JSON array

    -- Classification
    beverage_category VARCHAR(100),  -- Soft Drink / Tea / Coffee / Juice / Traditional / Alcoholic
    beverage_type VARCHAR(100),  -- carbonated / hot / cold / fermented
    is_alcoholic BOOLEAN DEFAULT FALSE,
    is_traditional BOOLEAN DEFAULT FALSE,
    region_code VARCHAR(10),

    -- Beverage properties
    serving_size_ml INTEGER DEFAULT 240,  -- Standard cup
    caffeine_mg DOUBLE PRECISION,
    alcohol_pct DOUBLE PRECISION,
    is_carbonated BOOLEAN DEFAULT FALSE,
    sugar_content VARCHAR(20),  -- none / low / medium / high

    -- Nutritional data (per 100ml or per serving)
    energy_kcal DOUBLE PRECISION,
    protein_g DOUBLE PRECISION,
    carbs_g DOUBLE PRECISION,
    fat_g DOUBLE PRECISION,
    sugar_g DOUBLE PRECISION,
    sodium_mg DOUBLE PRECISION,
    potassium_mg DOUBLE PRECISION,
    calcium_mg DOUBLE PRECISION,

    -- Health considerations
    is_diabetes_friendly BOOLEAN DEFAULT FALSE,
    is_ckd_friendly BOOLEAN DEFAULT FALSE,
    is_heart_healthy BOOLEAN DEFAULT FALSE,
    health_warnings TEXT,  -- "High sugar content", "Contains caffeine"

    -- Preparation (for traditional beverages)
    preparation_method TEXT,
    typical_ingredients TEXT,  -- JSON array

    -- Data source
    data_source VARCHAR(200),
    source_url VARCHAR(500),
    data_quality_self_rating INTEGER,

    -- Supporting evidence
    has_label_photo BOOLEAN DEFAULT FALSE,
    label_photo_url VARCHAR(500),

    -- Submission context
    submission_reason TEXT,
    cultural_significance TEXT,
    health_benefits TEXT,

    -- Review workflow
    status VARCHAR(20) DEFAULT 'pending',
    reviewed_by INTEGER,
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

CREATE INDEX idx_beverage_submissions_status ON beverage_submissions(status, submitted_at DESC);
CREATE INDEX idx_beverage_submissions_user ON beverage_submissions(submitted_by_user_id, submitted_at DESC);


-- ============================================================================
-- EXAMPLE SEED DATA
-- ============================================================================

INSERT INTO beverage_submissions (
    submitted_by_user_id, submitter_name,
    beverage_name, local_name, alternative_names,
    beverage_category, beverage_type, is_alcoholic, is_traditional, region_code,
    serving_size_ml, energy_kcal, carbs_g, sugar_g, sodium_mg,
    is_diabetes_friendly, health_warnings,
    preparation_method, typical_ingredients,
    data_source, data_quality_self_rating,
    submission_reason, cultural_significance,
    status
) VALUES (
    456, 'John Mwangi',
    'Mursik', 'Fermented Milk', '["Mursik", "Soured milk", "Kalenjin milk"]',
    'Traditional', 'fermented', FALSE, TRUE, 'KE',
    240, 65, 7.5, 7.0, 50,
    FALSE, 'Contains lactose, not suitable for lactose intolerant',
    'Milk fermented in a gourd (kibuyu) with charcoal from specific trees',
    '["cow milk", "goat milk", "charcoal from sodom apple tree"]',
    'Traditional preparation knowledge + nutritionist consultation',
    4,
    'Mursik is a traditional Kalenjin fermented milk drink that is culturally significant and has probiotic benefits',
    'Central to Kalenjin ceremonies and daily life. Believed to have medicinal properties. Rich in probiotics.',
    'pending'
);