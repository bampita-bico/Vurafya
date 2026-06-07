-- Migration 044b: Add PRIMARY Keys to Remaining Tables
-- Complete the PK addition for 11 remaining tables
-- Created: 2026-04-12
-- Note: Triggers and views already dropped, will be restored separately

-- ============================================================================
-- TABLE: drinks
-- ============================================================================

ALTER TABLE drinks RENAME TO drinks_old;

CREATE TABLE drinks (
    id SERIAL PRIMARY KEY,
    Cup_Name TEXT,
    Quantity_ml INTEGER,
    Instructions INTEGER,
    "user-id" INTEGER,
    beverage_id INTEGER,
    Timestamp INTEGER
);

DROP TABLE IF EXISTS drinks_old;

-- ============================================================================
-- TABLE: facility_partners
-- ============================================================================

ALTER TABLE facility_partners RENAME TO facility_partners_old;

CREATE TABLE facility_partners (
    id SERIAL PRIMARY KEY,
    name TEXT,
    type NUMERIC,
    location_gps DOUBLE PRECISION,
    commision_rate DOUBLE PRECISION
);

DROP TABLE IF EXISTS facility_partners_old;

-- ============================================================================
-- TABLE: food_safety_hazards
-- ============================================================================

ALTER TABLE food_safety_hazards RENAME TO food_safety_hazards_old;

CREATE TABLE food_safety_hazards (
    id SERIAL PRIMARY KEY,
    food_id INTEGER,
    aflatoxin_risk INTEGER,
    microbial_load_score INTEGER,
    toxin_type NUMERIC,
    storage_penalty DOUBLE PRECISION
);

DROP TABLE IF EXISTS food_safety_hazards_old;

-- ============================================================================
-- TABLE: food_submissions
-- ============================================================================

ALTER TABLE food_submissions RENAME TO food_submissions_old;

CREATE TABLE food_submissions (
    id SERIAL PRIMARY KEY,
    name TEXT,
    submitted_by TEXT,
    status TEXT,
    reviewed_at DOUBLE PRECISION
);

DROP TABLE IF EXISTS food_submissions_old;

-- ============================================================================
-- TABLE: kitchen_physics
-- ============================================================================

ALTER TABLE kitchen_physics RENAME TO kitchen_physics_old;

CREATE TABLE kitchen_physics (
    id SERIAL PRIMARY KEY,
    food_id INTEGER,
    refuse_percent DOUBLE PRECISION,
    water_yield_factor DOUBLE PRECISION,
    vitamin_retention DOUBLE PRECISION
);

DROP TABLE IF EXISTS kitchen_physics_old;

-- ============================================================================
-- TABLE: recipe_ingredients
-- ============================================================================

ALTER TABLE recipe_ingredients RENAME TO recipe_ingredients_old;

CREATE TABLE recipe_ingredients (
    id SERIAL PRIMARY KEY,
    recipe_id INTEGER,
    food_id INTEGER,
    quantity DOUBLE PRECISION
);

DROP TABLE IF EXISTS recipe_ingredients_old;

-- ============================================================================
-- TABLE: recipes
-- ============================================================================

ALTER TABLE recipes RENAME TO recipes_old;

CREATE TABLE recipes (
    id SERIAL PRIMARY KEY,
    name TEXT,
    created_by_user TEXT,
    verified TEXT,
    created_at DOUBLE PRECISION
);

DROP TABLE IF EXISTS recipes_old;

-- ============================================================================
-- TABLE: referral_tickets
-- ============================================================================

ALTER TABLE referral_tickets RENAME TO referral_tickets_old;

CREATE TABLE referral_tickets (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    doctor_id INTEGER,
    target_facility_id INTEGER,
    status INTEGER,
    Field6 NUMERIC,
    qr_code_hash BLOB
);

DROP TABLE IF EXISTS referral_tickets_old;

-- ============================================================================
-- TABLE: saved_drinks
-- ============================================================================

ALTER TABLE saved_drinks RENAME TO saved_drinks_old;

CREATE TABLE saved_drinks (
    id SERIAL PRIMARY KEY
);

DROP TABLE IF EXISTS saved_drinks_old;

-- ============================================================================
-- TABLE: saved_meals
-- ============================================================================

ALTER TABLE saved_meals RENAME TO saved_meals_old;

CREATE TABLE saved_meals (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    name TEXT,
    ceated_at DOUBLE PRECISION
);

DROP TABLE IF EXISTS saved_meals_old;

-- ============================================================================
-- TABLE: seasonal_availability
-- ============================================================================

ALTER TABLE seasonal_availability RENAME TO seasonal_availability_old;

CREATE TABLE seasonal_availability (
    id SERIAL PRIMARY KEY,
    Food_ID INTEGER,
    Month_Start TEXT,
    Month_End TEXT,
    Is_In_Season BLOB
);

DROP TABLE IF EXISTS seasonal_availability_old;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
