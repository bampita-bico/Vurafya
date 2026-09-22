"""Seed catalog invariants for the 300-food nutrition release."""

import csv
from pathlib import Path

from scripts.import_seed_postgres import PAN_AFRICAN_CATEGORY_NAMES


ROOT = Path(__file__).parent.parent


def _rows(filename: str) -> list[dict[str, str]]:
    with (ROOT / "seed_data" / filename).open(encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def test_all_food_seed_ids_are_preserved_and_unique():
    east_african = _rows("foods.csv")
    pan_african = _rows("pan_african_foods.csv")
    ids = [int(row["id"]) for row in east_african + pan_african]

    assert len(ids) == 300
    assert len(ids) == len(set(ids))
    assert min(ids) == 1
    assert max(ids) == 302


def test_beverages_are_categorised_for_household_portions():
    east_african = _rows("foods.csv")
    pan_african = _rows("pan_african_foods.csv")

    assert sum(row["category"] == "Beverages" for row in east_african) == 4
    pan_beverages = [row for row in pan_african if row["category_id"] == "9"]
    assert len(pan_beverages) == 4
    assert PAN_AFRICAN_CATEGORY_NAMES["9"] == "Beverages"


def test_every_catalog_food_has_a_valid_nutrition_source():
    catalog_ids = {
        int(row["id"])
        for row in _rows("foods.csv") + _rows("pan_african_foods.csv")
    }
    east_nutrient_ids = {
        int(row["food_id"])
        for row in _rows("east_african_food_nutrients.csv")
    }
    pan_nutrient_ids = {
        int(row["food_id"])
        for row in _rows("pan_african_food_nutrients.csv")
    }

    # The two legacy East-African records without catalog foods are rejected
    # by the PostgreSQL importer; active catalog foods retain full coverage.
    assert east_nutrient_ids - catalog_ids == {101, 102}
    assert pan_nutrient_ids <= catalog_ids
    assert catalog_ids <= east_nutrient_ids | pan_nutrient_ids
