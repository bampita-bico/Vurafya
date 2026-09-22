-- CSV imports are repeatable. A food has one value per nutrient in the
-- application catalog, so collapse accidental historical duplicates first.
DELETE FROM food_nutrients duplicate
USING food_nutrients canonical
WHERE duplicate.food_id = canonical.food_id
  AND duplicate.nutrient_id = canonical.nutrient_id
  AND duplicate.id > canonical.id;

CREATE UNIQUE INDEX IF NOT EXISTS uq_food_nutrients_food_nutrient
    ON food_nutrients(food_id, nutrient_id);
