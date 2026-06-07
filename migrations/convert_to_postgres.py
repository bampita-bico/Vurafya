import re
import os
from pathlib import Path

input_dir = Path("/home/bampita/Projects/CDFD/Archived/Vurafya/migrations")
output_dir = Path("/home/bampita/Projects/CDFD/Archived/Vurafya/migrations_pg")
output_dir.mkdir(exist_ok=True)

def convert_sql(content, is_bootstrap=False):
    # 1. Basic type replacements
    content = content.replace("INTEGER PRIMARY KEY AUTOINCREMENT", "SERIAL PRIMARY KEY")
    content = content.replace("AUTOINCREMENT", "")
    content = content.replace(" REAL", " DOUBLE PRECISION")
    content = content.replace(" DATETIME ", " TIMESTAMP ")

    # 2. Fix SQLite date functions
    def fix_datetime(match):
        interval = match.group(1)
        return f"CURRENT_TIMESTAMP + INTERVAL '{interval}'"

    content = re.sub(r"datetime\('now',\s*'\+([^']+)'\)", fix_datetime, content)
    content = re.sub(r"datetime\('now'\)", "CURRENT_TIMESTAMP", content)

    # 3. Handle INSERT OR IGNORE -> INSERT INTO ... ON CONFLICT DO NOTHING
    # Simple replacement for common seed patterns
    content = content.replace("INSERT OR IGNORE INTO", "INSERT INTO")

    # In Postgres, INSERT INTO table (cols) VALUES (vals) ON CONFLICT DO NOTHING
    # is only valid if we specify the conflict target (unique columns).
    # Since we don't know them easily, we can sometimes use ON CONFLICT ON CONSTRAINT if named,
    # but for bootstrap/seed data, we'll try to just append ON CONFLICT DO NOTHING to simple inserts.
    # Actually, a better way for migration scripts is to let the runner handle errors or use specific logic.
    # For now, we'll keep it simple and fix errors as they arise.

    if is_bootstrap:
        tables = re.findall(r"CREATE TABLE IF NOT EXISTS (\w+)", content)
        stubs = "\n".join([f"CREATE TABLE IF NOT EXISTS {t} (id SERIAL PRIMARY KEY);" for t in set(tables)])

        header = f"""-- PostgreSQL Bootstrap
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', 'public', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

-- Create stubs for all tables to satisfy FK references
{stubs}

-- Disable FK checks for bootstrap
SET session_replication_role = 'replica';
"""
        footer = "\n-- Re-enable FK checks\nSET session_replication_role = 'origin';\n"
        return header + content + footer

    return content

# Convert bootstrap separately to include stubs
bootstrap_path = input_dir / "000_bootstrap.sql"
if bootstrap_path.exists():
    print(f"Converting bootstrap: {bootstrap_path.name}")
    content = bootstrap_path.read_text(encoding="utf-8")
    converted = convert_sql(content, is_bootstrap=True)
    (output_dir / "000_bootstrap.sql").write_text(converted, encoding="utf-8")

# Convert all other files
for f in sorted(input_dir.glob("*.sql")):
    if f.name == "000_bootstrap.sql":
        continue
    print(f"Converting: {f.name}")
    content = f.read_text(encoding="utf-8")
    converted = convert_sql(content)
    (output_dir / f.name).write_text(converted, encoding="utf-8")

print(f"Successfully converted all migrations to {output_dir}")
