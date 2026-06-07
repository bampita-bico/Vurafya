#!/usr/bin/env python3
"""
Vurafya Seed Data Import Script
Imports all CSV seed data files into AfyaFigo.db
"""

import sqlite3
import csv
import os
import sys
import json
from datetime import datetime
from pathlib import Path

# Database path
DB_PATH = Path(__file__).parent.parent / "AfyaFigo.db"
SEED_DATA_DIR = Path(__file__).parent.parent / "seed_data"

# Import order (respects foreign key dependencies)
IMPORT_ORDER = [
    # Master reference data (no dependencies)
    ("nutrients", "nutrients.csv"),
    ("foods", "foods.csv"),
    ("drug_categories", "drug_categories.csv"),
    ("medications", "medications.csv"),

    # Dependent data (requires master data)
    ("food_nutrients", "food_nutrients.csv"),
    ("glycemic_load_index", "glycemic_load_index.csv"),
    ("renal_acid_load_data", "renal_acid_load_data.csv"),

    # Drug interactions (requires medications and foods)
    ("drug_drug_interactions", "drug_drug_interactions.csv"),
    ("drug_food_interactions", "drug_food_interactions.csv"),
    ("drug_beverage_interactions", "drug_beverage_interactions.csv"),

    # Facilities and partners
    ("partner_facilities", "partner_facilities.csv"),

    # Payment system data
    ("currency_exchange_rates", "currency_exchange_rates.csv"),
    ("labor_skill_categories", "labor_skill_categories.csv"),
]


def connect_db():
    """Connect to SQLite database with foreign key support"""
    conn = sqlite3.connect(DB_PATH)
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def get_table_columns(conn, table_name):
    """Get list of column names for a table"""
    cursor = conn.cursor()
    cursor.execute(f"PRAGMA table_info({table_name})")
    return [col[1] for col in cursor.fetchall()]


def import_csv_to_table(conn, table_name, csv_path):
    """
    Import CSV file into database table

    Args:
        conn: SQLite connection
        table_name: Target table name
        csv_path: Path to CSV file

    Returns:
        Number of rows inserted
    """
    cursor = conn.cursor()

    if not csv_path.exists():
        print(f"  ⚠️  CSV file not found: {csv_path}")
        return 0

    # Get existing table columns
    table_columns = get_table_columns(conn, table_name)
    if not table_columns:
        print(f"  ❌ Table {table_name} does not exist")
        return 0

    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        rows = list(reader)

        if not rows:
            print(f"  ℹ️  No data in CSV file")
            return 0

        # Get column names from CSV header
        csv_columns = list(rows[0].keys())

        # Find matching columns (intersection), exclude 'id' if AUTOINCREMENT
        matching_columns = []
        skipped_columns = []

        for col in csv_columns:
            # Skip 'id' column if table has it (assume AUTOINCREMENT)
            if col == 'id' and 'id' in table_columns:
                skipped_columns.append(col + ' (AUTOINCREMENT)')
                continue

            if col in table_columns:
                matching_columns.append(col)
            else:
                skipped_columns.append(col)

        if skipped_columns:
            print(f"  ℹ️  Skipping columns not in table: {', '.join(skipped_columns)}")

        if not matching_columns:
            print(f"  ❌ No matching columns between CSV and table")
            return 0

        print(f"  📥 Importing columns: {', '.join(matching_columns)}")

        # Prepare INSERT statement
        placeholders = ','.join(['?' for _ in matching_columns])
        column_names = ','.join([f'"{col}"' for col in matching_columns])
        insert_sql = f'INSERT INTO {table_name} ({column_names}) VALUES ({placeholders})'

        inserted_count = 0
        failed_count = 0

        for row_num, row in enumerate(rows, start=2):  # Start at 2 (line 1 is header)
            try:
                # Convert values for matching columns only
                values = []
                for col in matching_columns:
                    value = row[col]

                    # Handle NULL/None
                    if value == 'NULL' or value == '':
                        values.append(None)
                    # Handle boolean strings
                    elif value == 'TRUE':
                        values.append(1)
                    elif value == 'FALSE':
                        values.append(0)
                    # Handle JSON arrays/objects (check if starts with [ or {)
                    elif isinstance(value, str) and (value.startswith('[') or value.startswith('{')):
                        # Validate JSON
                        try:
                            json.loads(value)
                            values.append(value)  # Store as TEXT
                        except json.JSONDecodeError:
                            # Not valid JSON, store as-is
                            values.append(value)
                    else:
                        values.append(value)

                cursor.execute(insert_sql, values)
                inserted_count += 1

            except sqlite3.IntegrityError as e:
                failed_count += 1
                if failed_count <= 3:  # Only show first 3 errors
                    print(f"    ⚠️  Row {row_num} failed: {e}")
            except sqlite3.Error as e:
                failed_count += 1
                if failed_count <= 3:
                    print(f"    ❌ Row {row_num} error: {e}")

        if failed_count > 3:
            print(f"    ... and {failed_count - 3} more errors (suppressed)")

        conn.commit()

        print(f"  ✅ Inserted {inserted_count} rows", end="")
        if failed_count > 0:
            print(f" ({failed_count} failed)", end="")
        print()

        return inserted_count


def verify_data(conn):
    """
    Verify imported data with sample queries
    """
    cursor = conn.cursor()

    print("\n" + "="*60)
    print("DATA VERIFICATION")
    print("="*60)

    # Check row counts
    checks = [
        ("nutrients", "SELECT COUNT(*) FROM nutrients"),
        ("foods", "SELECT COUNT(*) FROM foods"),
        ("food_nutrients", "SELECT COUNT(*) FROM food_nutrients"),
        ("medications", "SELECT COUNT(*) FROM medications"),
        ("drug_categories", "SELECT COUNT(*) FROM drug_categories"),
        ("drug_drug_interactions", "SELECT COUNT(*) FROM drug_drug_interactions"),
        ("drug_food_interactions", "SELECT COUNT(*) FROM drug_food_interactions"),
        ("partner_facilities", "SELECT COUNT(*) FROM partner_facilities"),
        ("glycemic_load_index", "SELECT COUNT(*) FROM glycemic_load_index"),
        ("renal_acid_load_data", "SELECT COUNT(*) FROM renal_acid_load_data"),
    ]

    print("\n📊 Row Counts:")
    for table, query in checks:
        try:
            cursor.execute(query)
            count = cursor.fetchone()[0]
            print(f"  {table:30} {count:>5} rows")
        except sqlite3.Error as e:
            print(f"  {table:30} ERROR: {e}")

    # Sample queries
    print("\n🔍 Sample Queries:\n")

    # 1. Foods with nutrients
    print("1. Sample foods with protein content:")
    cursor.execute("""
        SELECT f.name, fn.amount_per_100g, n.unit
        FROM foods f
        JOIN food_nutrients fn ON f.id = fn.food_id
        JOIN nutrients n ON fn.nutrient_id = n.id
        WHERE n.name = 'Protein'
        ORDER BY fn.amount_per_100g DESC
        LIMIT 5
    """)
    for row in cursor.fetchall():
        print(f"   - {row[0]:40} {row[1]:>6}{row[2]}")

    # 2. High glycemic load foods
    print("\n2. High glycemic load foods (GL ≥ 20):")
    cursor.execute("""
        SELECT food_name, glycemic_load, gl_category
        FROM glycemic_load_index
        WHERE gl_category = 'high'
        ORDER BY glycemic_load DESC
        LIMIT 5
    """)
    for row in cursor.fetchall():
        print(f"   - {row[0]:40} GL={row[1]:>5} ({row[2]})")

    # 3. CKD-friendly foods
    print("\n3. CKD-friendly foods (negative PRAL):")
    cursor.execute("""
        SELECT food_name, pral_value, ckd_recommendation
        FROM renal_acid_load_data
        WHERE ckd_recommendation = 'encourage'
        ORDER BY pral_value
        LIMIT 5
    """)
    for row in cursor.fetchall():
        print(f"   - {row[0]:40} PRAL={row[1]:>6} ({row[2]})")

    # 4. Severe drug-drug interactions
    print("\n4. Severe drug-drug interactions:")
    cursor.execute("""
        SELECT m1.generic_name, m2.generic_name, ddi.severity, ddi.interaction_type
        FROM drug_drug_interactions ddi
        JOIN medications m1 ON ddi.drug_a_id = m1.id
        JOIN medications m2 ON ddi.drug_b_id = m2.id
        WHERE ddi.severity IN ('severe', 'contraindicated')
        LIMIT 5
    """)
    for row in cursor.fetchall():
        print(f"   - {row[0]} + {row[1]:30} ({row[2]}, {row[3]})")

    # 5. Partner facilities by country
    print("\n5. Partner facilities by country:")
    cursor.execute("""
        SELECT region_code, COUNT(*) as facility_count
        FROM partner_facilities
        WHERE region_code LIKE 'UG%' OR region_code LIKE 'KE%' OR region_code LIKE 'TZ%'
        GROUP BY SUBSTR(region_code, 1, 2)
    """)
    for row in cursor.fetchall():
        country = row[0][:2]
        country_name = {'UG': 'Uganda', 'KE': 'Kenya', 'TZ': 'Tanzania'}.get(country, country)
        print(f"   - {country_name:30} {row[1]:>3} facilities")


def main():
    """Main import function"""
    print("="*60)
    print("VURAFYA SEED DATA IMPORT")
    print("="*60)
    print(f"Database: {DB_PATH}")
    print(f"Seed Data: {SEED_DATA_DIR}")
    print()

    if not DB_PATH.exists():
        print(f"❌ ERROR: Database not found at {DB_PATH}")
        print("Please ensure AfyaFigo.db exists in the project root.")
        sys.exit(1)

    if not SEED_DATA_DIR.exists():
        print(f"❌ ERROR: Seed data directory not found at {SEED_DATA_DIR}")
        sys.exit(1)

    # Connect to database
    try:
        conn = connect_db()
        print("✅ Connected to database\n")
    except sqlite3.Error as e:
        print(f"❌ ERROR: Could not connect to database: {e}")
        sys.exit(1)

    # Import each CSV file
    total_inserted = 0

    for table_name, csv_filename in IMPORT_ORDER:
        csv_path = SEED_DATA_DIR / csv_filename
        print(f"📂 Importing {csv_filename} → {table_name}")

        try:
            count = import_csv_to_table(conn, table_name, csv_path)
            total_inserted += count
        except Exception as e:
            print(f"  ❌ ERROR: {e}")
            conn.rollback()
            continue

    # Verify imported data
    verify_data(conn)

    # Summary
    print("\n" + "="*60)
    print(f"✅ IMPORT COMPLETE")
    print(f"   Total rows inserted: {total_inserted}")
    print("="*60)

    conn.close()


if __name__ == "__main__":
    main()
