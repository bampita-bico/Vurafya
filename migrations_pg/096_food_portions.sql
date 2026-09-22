-- Household measures are explicit planning estimates. Nutrient calculation is
-- always based on the resolved gram amount, never on an ambiguous label alone.
CREATE TABLE IF NOT EXISTS food_portions (
    id SERIAL PRIMARY KEY,
    food_id INTEGER NOT NULL REFERENCES foods(id) ON DELETE CASCADE,
    portion_name VARCHAR(80) NOT NULL,
    grams DOUBLE PRECISION NOT NULL CHECK (grams > 0),
    milliliters DOUBLE PRECISION CHECK (milliliters IS NULL OR milliliters > 0),
    is_estimate BOOLEAN NOT NULL DEFAULT TRUE,
    display_order INTEGER NOT NULL DEFAULT 0,
    UNIQUE (food_id, portion_name)
);

CREATE INDEX IF NOT EXISTS idx_food_portions_food ON food_portions(food_id, display_order);
