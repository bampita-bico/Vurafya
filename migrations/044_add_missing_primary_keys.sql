-- Migration 044: Add Missing PRIMARY Keys
-- Fix schema quality issues - add PRIMARY KEYs to 18 tables
-- Created: 2026-04-12
-- All affected tables are currently empty (0 rows)

-- ============================================================================
-- STEP 1: DROP ALL TRIGGERS
-- ============================================================================


-- ============================================================================
-- STEP 2: DROP ALL VIEWS
-- ============================================================================


-- ============================================================================
-- STEP 3: RECREATE TABLES WITH PRIMARY KEYS
-- ============================================================================

-- TABLE: allergy_flags
ALTER TABLE allergy_flags RENAME TO allergy_flags_old;

CREATE TABLE allergy_flags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    food_id INTEGER NOT NULL,
    Is_Allergen BLOB,
    Allergen_Type NUMERIC,
    Is_High_Oxalate BLOB
);

DROP TABLE IF EXISTS allergy_flags_old;

-- TABLE: beverage_submissions
ALTER TABLE beverage_submissions RENAME TO beverage_submissions_old;

CREATE TABLE beverage_submissions (
    id INTEGER PRIMARY KEY AUTOINCREMENT
);

DROP TABLE IF EXISTS beverage_submissions_old;

-- TABLE: beverages
ALTER TABLE beverages RENAME TO beverages_old;

CREATE TABLE beverages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    sugar_content_g INTEGER,
    alcohol_percentage INTEGER,
    Caffeine INTEGER,
    Phosphorous_mg INTEGER,
    Potassium_mg INTEGER,
    Energy_kcal INTEGER
);

DROP TABLE IF EXISTS beverages_old;

-- TABLE: category_nutrients
ALTER TABLE category_nutrients RENAME TO category_nutrients_old;

CREATE TABLE category_nutrients (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    category_id INTEGER,
    nutrient_id INTEGER,
    average_value TEXT
);

DROP TABLE IF EXISTS category_nutrients_old;

-- TABLE: cocktail_ingredients
ALTER TABLE cocktail_ingredients RENAME TO cocktail_ingredients_old;

CREATE TABLE cocktail_ingredients (
    id INTEGER PRIMARY KEY AUTOINCREMENT
);

DROP TABLE IF EXISTS cocktail_ingredients_old;

-- TABLE: cocktails
ALTER TABLE cocktails RENAME TO cocktails_old;

CREATE TABLE cocktails (
    id INTEGER PRIMARY KEY AUTOINCREMENT
);

DROP TABLE IF EXISTS cocktails_old;

-- TABLE: drink_components
ALTER TABLE drink_components RENAME TO drink_components_old;

CREATE TABLE drink_components (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    Recipe_ID INTEGER,
    Recipe_Name INTEGER,
    Quantity_ml INTEGER
);

DROP TABLE IF EXISTS drink_components_old;

-- TABLE: drinks
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

-- TABLE: facility_partners
ALTER TABLE facility_partners RENAME TO facility_partners_old;

CREATE TABLE facility_partners (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    type NUMERIC,
    location_gps REAL,
    commision_rate REAL
);

DROP TABLE IF EXISTS facility_partners_old;

-- TABLE: food_safety_hazards
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

-- TABLE: food_submissions
ALTER TABLE food_submissions RENAME TO food_submissions_old;

CREATE TABLE food_submissions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    submitted_by TEXT,
    status TEXT,
    reviewed_at REAL
);

DROP TABLE IF EXISTS food_submissions_old;

-- TABLE: kitchen_physics
ALTER TABLE kitchen_physics RENAME TO kitchen_physics_old;

CREATE TABLE kitchen_physics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    food_id INTEGER,
    refuse_percent REAL,
    water_yield_factor REAL,
    vitamin_retention REAL
);

DROP TABLE IF EXISTS kitchen_physics_old;

-- TABLE: recipe_ingredients
ALTER TABLE recipe_ingredients RENAME TO recipe_ingredients_old;

CREATE TABLE recipe_ingredients (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    recipe_id INTEGER,
    food_id INTEGER,
    quantity REAL
);

DROP TABLE IF EXISTS recipe_ingredients_old;

-- TABLE: recipes
ALTER TABLE recipes RENAME TO recipes_old;

CREATE TABLE recipes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    created_by_user TEXT,
    verified TEXT,
    created_at REAL
);

DROP TABLE IF EXISTS recipes_old;

-- TABLE: referral_tickets
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

-- TABLE: saved_drinks
ALTER TABLE saved_drinks RENAME TO saved_drinks_old;

CREATE TABLE saved_drinks (
    id INTEGER PRIMARY KEY AUTOINCREMENT
);

DROP TABLE IF EXISTS saved_drinks_old;

-- TABLE: saved_meals
ALTER TABLE saved_meals RENAME TO saved_meals_old;

CREATE TABLE saved_meals (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    name TEXT,
    ceated_at REAL
);

DROP TABLE IF EXISTS saved_meals_old;

-- TABLE: seasonal_availability
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
-- STEP 4: RECREATE ALL VIEWS
-- ============================================================================

-- ============================================================================
-- STEP 5: RECREATE ALL TRIGGERS
-- ============================================================================

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
