-- Migration 044b: Add PRIMARY Keys to Remaining Tables
-- Complete the PK addition for 11 remaining tables
-- Created: 2026-04-12
-- Note: Triggers and views already dropped, will be restored separately

-- ============================================================================
-- TABLE: drinks
-- ============================================================================

ALTER TABLE drinks RENAME TO drinks_old;

CREATE TABLE drinks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
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
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    type NUMERIC,
    location_gps REAL,
    commision_rate REAL
);

DROP TABLE IF EXISTS facility_partners_old;

-- ============================================================================
-- TABLE: food_safety_hazards
-- ============================================================================

ALTER TABLE food_safety_hazards RENAME TO food_safety_hazards_old;

CREATE TABLE food_safety_hazards (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    food_id INTEGER,
    aflatoxin_risk INTEGER,
    microbial_load_score INTEGER,
    toxin_type NUMERIC,
    storage_penalty REAL
);

DROP TABLE IF EXISTS food_safety_hazards_old;

-- ============================================================================
-- TABLE: food_submissions
-- ============================================================================

ALTER TABLE food_submissions RENAME TO food_submissions_old;

CREATE TABLE food_submissions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    submitted_by TEXT,
    status TEXT,
    reviewed_at REAL
);

DROP TABLE IF EXISTS food_submissions_old;

-- ============================================================================
-- TABLE: kitchen_physics
-- ============================================================================

ALTER TABLE kitchen_physics RENAME TO kitchen_physics_old;

CREATE TABLE kitchen_physics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    food_id INTEGER,
    refuse_percent REAL,
    water_yield_factor REAL,
    vitamin_retention REAL
);

DROP TABLE IF EXISTS kitchen_physics_old;

-- ============================================================================
-- TABLE: recipe_ingredients
-- ============================================================================

ALTER TABLE recipe_ingredients RENAME TO recipe_ingredients_old;

CREATE TABLE recipe_ingredients (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    recipe_id INTEGER,
    food_id INTEGER,
    quantity REAL
);

DROP TABLE IF EXISTS recipe_ingredients_old;

-- ============================================================================
-- TABLE: recipes
-- ============================================================================

ALTER TABLE recipes RENAME TO recipes_old;

CREATE TABLE recipes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    created_by_user TEXT,
    verified TEXT,
    created_at REAL
);

DROP TABLE IF EXISTS recipes_old;

-- ============================================================================
-- TABLE: referral_tickets
-- ============================================================================

ALTER TABLE referral_tickets RENAME TO referral_tickets_old;

CREATE TABLE referral_tickets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
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
    id INTEGER PRIMARY KEY AUTOINCREMENT
);

DROP TABLE IF EXISTS saved_drinks_old;

-- ============================================================================
-- TABLE: saved_meals
-- ============================================================================

ALTER TABLE saved_meals RENAME TO saved_meals_old;

CREATE TABLE saved_meals (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    name TEXT,
    ceated_at REAL
);

DROP TABLE IF EXISTS saved_meals_old;

-- ============================================================================
-- TABLE: seasonal_availability
-- ============================================================================

ALTER TABLE seasonal_availability RENAME TO seasonal_availability_old;

CREATE TABLE seasonal_availability (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    Food_ID INTEGER,
    Month_Start TEXT,
    Month_End TEXT,
    Is_In_Season BLOB
);

DROP TABLE IF EXISTS seasonal_availability_old;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
