#!/usr/bin/env python3
"""Import Vurafya seed_data CSV files into PostgreSQL."""

from __future__ import annotations

import csv
import json
import os
import sys
from pathlib import Path

import psycopg2
from psycopg2.extras import execute_batch

BASE_DIR = Path(__file__).parent.parent
SEED_DATA_DIR = BASE_DIR / "seed_data"
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://cdfd:change-me-postgres-password@localhost:5435/cdfd",
)

IMPORT_ORDER: list[tuple[str, str | list[str]]] = [
    ("nutrients", "nutrients_fixed.csv"),
    ("foods", ["foods.csv", "pan_african_foods.csv"]),
    ("drug_categories", "drug_categories_fixed.csv"),
    ("medications", "medications_fixed.csv"),
    ("food_nutrients", ["east_african_food_nutrients.csv", "pan_african_food_nutrients.csv"]),
    ("glycemic_load_index", "glycemic_load_index.csv"),
    ("renal_acid_load_data", "renal_acid_load_data.csv"),
    ("drug_drug_interactions", "drug_drug_interactions_fixed.csv"),
    ("drug_food_interactions", "drug_food_interactions_fixed.csv"),
    ("drug_beverage_interactions", "drug_beverage_interactions_fixed.csv"),
]

PAN_AFRICAN_CATEGORY_NAMES = {
    "1": "Starchy Staples",
    "2": "Legumes & Pulses",
    "3": "Animal Proteins",
    "4": "Vegetables",
    "5": "Fruits",
    "6": "Soups & Stews",
    "7": "Dairy",
    "8": "Sweets & Desserts",
    "9": "Beverages",
    "11": "Mixed Dishes",
}

FOOD_COLUMN_ALIASES = {
    "category_id": "category",
    "region": "region_code",
    "verified": "is_verified",
}

REGION_CODES = {
    "West Africa": "AF-WEST",
    "Central Africa": "AF-CENTRAL",
    "Southern Africa": "AF-SOUTH",
    "North Africa": "AF-NORTH",
}


def get_table_columns(conn, table_name: str) -> list[str]:
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT column_name FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = %s
            ORDER BY ordinal_position
            """,
            (table_name,),
        )
        return [row[0] for row in cur.fetchall()]


def normalize_value(value: str | None):
    if value is None or value == "" or value == "NULL":
        return None
    if value == "TRUE":
        return True
    if value == "FALSE":
        return False
    if isinstance(value, str) and (value.startswith("[") or value.startswith("{")):
        try:
            json.loads(value)
            return value
        except json.JSONDecodeError:
            return value
    return value


def import_csv(conn, table_name: str, csv_path: Path) -> int:
    if not csv_path.exists():
        print(f"  skip missing {csv_path.name}")
        return 0

    table_columns = get_table_columns(conn, table_name)
    if not table_columns:
        print(f"  table missing: {table_name}")
        return 0

    with csv_path.open(encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    if not rows:
        return 0

    csv_columns = list(rows[0].keys())
    column_sources = (
        {FOOD_COLUMN_ALIASES.get(column, column): column for column in csv_columns}
        if table_name == "foods"
        else {column: column for column in csv_columns}
    )
    matching = [
        col
        for col in column_sources
        if col in table_columns
    ]
    if not matching:
        print(f"  no matching columns for {csv_path.name} -> {table_name}")
        return 0

    # Nutrient files predate the consolidated 300-food catalog and include
    # legacy IDs with no corresponding food.  Keep the import referentially
    # sound instead of silently creating orphan nutrition facts.
    known_food_ids: set[int] | None = None
    if table_name == "food_nutrients":
        with conn.cursor() as cur:
            cur.execute("SELECT id FROM foods")
            known_food_ids = {row[0] for row in cur.fetchall()}

    column_sql = ", ".join(f'"{c}"' for c in matching)
    placeholders = ", ".join(["%s"] * len(matching))
    sql = f'INSERT INTO {table_name} ({column_sql}) VALUES ({placeholders}) ON CONFLICT DO NOTHING'

    values = []
    skipped = 0
    skipped_unknown_food = 0
    for row in rows:
        try:
            record = []
            record_by_column = {}
            for col in matching:
                val = normalize_value(row.get(column_sources[col]))
                if table_name == "foods" and col == "category":
                    val = PAN_AFRICAN_CATEGORY_NAMES.get(str(val), val)
                if table_name == "foods" and col == "region_code":
                    val = REGION_CODES.get(str(val), val)
                if col in {"food_id", "nutrient_id", "meal_id", "user_id"} and val is not None:
                    val = int(float(val))
                if col == "id" and val is not None:
                    val = int(float(val))
                if col in {"amount_per_100g", "glycemic_index", "glycemic_load", "pral_value"} and val is not None:
                    val = float(val)
                record.append(val)
                record_by_column[col] = val
            if (
                known_food_ids is not None
                and record_by_column.get("food_id") not in known_food_ids
            ):
                skipped_unknown_food += 1
                continue
            values.append(tuple(record))
        except (TypeError, ValueError):
            skipped += 1
            continue

    if skipped:
        print(f"  skipped {skipped} invalid rows in {csv_path.name}")
    if skipped_unknown_food:
        print(f"  skipped {skipped_unknown_food} rows for foods absent from the catalog")

    with conn.cursor() as cur:
        execute_batch(cur, sql, values, page_size=500)
        if table_name == "foods" and "id" in matching:
            cur.execute(
                """SELECT setval(pg_get_serial_sequence(%s, 'id'),
                                   COALESCE((SELECT MAX(id) FROM foods), 1), TRUE)""",
                (table_name,),
            )
    conn.commit()
    print(f"  {csv_path.name}: {len(values)} rows -> {table_name}")
    return len(values)


def seed_food_portions(conn) -> int:
    """Add editable household-measure estimates for every seeded food."""
    statements = [
        """
        INSERT INTO food_portions (food_id, portion_name, grams, milliliters, is_estimate, display_order)
        SELECT id, '100 g', 100, NULL, FALSE, 1 FROM foods
        ON CONFLICT (food_id, portion_name) DO NOTHING
        """,
        """
        INSERT INTO food_portions (food_id, portion_name, grams, milliliters, is_estimate, display_order)
        SELECT id, '1 cup', 250, 250, TRUE, 2 FROM foods WHERE category = 'Beverages'
        ON CONFLICT (food_id, portion_name) DO NOTHING
        """,
        """
        INSERT INTO food_portions (food_id, portion_name, grams, milliliters, is_estimate, display_order)
        SELECT id, '1 bottle', 500, 500, TRUE, 3 FROM foods WHERE category = 'Beverages'
        ON CONFLICT (food_id, portion_name) DO NOTHING
        """,
        """
        INSERT INTO food_portions (food_id, portion_name, grams, milliliters, is_estimate, display_order)
        SELECT id, '1 cup', 150, NULL, TRUE, 2 FROM foods WHERE category IS DISTINCT FROM 'Beverages'
        ON CONFLICT (food_id, portion_name) DO NOTHING
        """,
        """
        INSERT INTO food_portions (food_id, portion_name, grams, milliliters, is_estimate, display_order)
        SELECT id, '1 plate', 350, NULL, TRUE, 3 FROM foods WHERE category IS DISTINCT FROM 'Beverages'
        ON CONFLICT (food_id, portion_name) DO NOTHING
        """,
    ]
    with conn.cursor() as cur:
        for statement in statements:
            cur.execute(statement)
        cur.execute("SELECT COUNT(*) FROM food_portions")
        count = cur.fetchone()[0]
    conn.commit()
    print(f"  food_portions: {count} presets")
    return count


def verify(conn):
    checks = ["nutrients", "foods", "food_nutrients", "medications"]
    print("\nRow counts:")
    with conn.cursor() as cur:
        for table in checks:
            cur.execute(f"SELECT COUNT(*) FROM {table}")
            print(f"  {table}: {cur.fetchone()[0]}")


def main() -> int:
    print("Vurafya seed import -> PostgreSQL")
    print(DATABASE_URL.split("@")[-1])

    conn = psycopg2.connect(DATABASE_URL)
    conn.autocommit = False
    total = 0
    for table_name, files in IMPORT_ORDER:
        paths = files if isinstance(files, list) else [files]
        print(f"\n{table_name}:")
        for filename in paths:
            total += import_csv(conn, table_name, SEED_DATA_DIR / filename)

    total += seed_food_portions(conn)

    verify(conn)
    conn.close()
    print(f"\nDone. {total} rows inserted (attempted).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
