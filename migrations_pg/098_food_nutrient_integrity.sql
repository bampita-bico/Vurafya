-- The legacy overlap CSV contained food IDs absent from the authoritative
-- 300-food regional catalog. Remove only dangling rows, then enforce the
-- relationship so future imports cannot create them.
DELETE FROM food_nutrients fn
WHERE NOT EXISTS (SELECT 1 FROM foods f WHERE f.id = fn.food_id);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_food_nutrients_food'
    ) THEN
        ALTER TABLE food_nutrients
            ADD CONSTRAINT fk_food_nutrients_food
            FOREIGN KEY (food_id) REFERENCES foods(id) ON DELETE CASCADE;
    END IF;
END $$;
