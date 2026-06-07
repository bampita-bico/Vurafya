#!/usr/bin/env python3
"""
Vurafya Migration Runner (Universal: SQLite + PostgreSQL)
Applies all SQL migrations in order.
"""

import os
import sys
import argparse
from pathlib import Path
from datetime import datetime

# Database Configuration
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///AfyaFigo.db")
BASE_DIR = Path(__file__).parent.parent

def get_connection():
    if DATABASE_URL.startswith("postgresql://") or DATABASE_URL.startswith("postgres://"):
        import psycopg2
        from psycopg2.extras import RealDictCursor
        # Convert postgres:// to postgresql:// if needed for some drivers,
        # but psycopg2 handles both.
        conn = psycopg2.connect(DATABASE_URL)
        conn.autocommit = True
        return conn, "postgresql"
    else:
        import sqlite3
        db_path = BASE_DIR / "AfyaFigo.db"
        conn = sqlite3.connect(str(db_path))
        conn.row_factory = sqlite3.Row
        return conn, "sqlite"

def ensure_migrations_table(conn, db_type):
    if db_type == "postgresql":
        with conn.cursor() as cur:
            cur.execute("""
                CREATE TABLE IF NOT EXISTS schema_migrations (
                    id        SERIAL PRIMARY KEY,
                    filename  VARCHAR(200) NOT NULL UNIQUE,
                    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
    else:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS schema_migrations (
                id        INTEGER PRIMARY KEY AUTOINCREMENT,
                filename  VARCHAR(200) NOT NULL UNIQUE,
                applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        conn.commit()

def get_applied(conn, db_type):
    if db_type == "postgresql":
        with conn.cursor() as cur:
            cur.execute("SELECT filename FROM schema_migrations")
            return {row[0] for row in cur.fetchall()}
    else:
        cursor = conn.execute("SELECT filename FROM schema_migrations")
        return {row["filename"] for row in cursor.fetchall()}

def apply_migration(conn, db_type, path: Path, verbose: bool = True):
    sql = path.read_text(encoding="utf-8")
    try:
        if db_type == "postgresql":
            with conn.cursor() as cur:
                cur.execute(sql)
            with conn.cursor() as cur:
                cur.execute(
                    "INSERT INTO schema_migrations (filename) VALUES (%s)",
                    (path.name,)
                )
        else:
            conn.executescript(sql)
            conn.execute(
                "INSERT INTO schema_migrations (filename, applied_at) VALUES (?, ?)",
                (path.name, datetime.now().isoformat()),
            )
            conn.commit()
        return True
    except Exception as e:
        msg = str(e)
        if "already exists" in msg.lower() or "duplicate column" in msg.lower():
            if verbose: print(f"    WARNING (idempotent): {msg[:80]}")
            return True
        print(f"  ✗ ERROR in {path.name}: {msg}")
        return False

def cmd_migrate(verbose: bool = True):
    conn, db_type = get_connection()
    ensure_migrations_table(conn, db_type)
    applied = get_applied(conn, db_type)

    # Choose migration directory based on DB type
    migrations_dir = BASE_DIR / ("migrations_pg" if db_type == "postgresql" else "migrations")
    files = sorted(migrations_dir.glob("*.sql"))
    pending = [f for f in files if f.name not in applied]

    if not pending:
        print(f"✓ Database ({db_type}) is up to date. ({len(applied)} migrations applied)")
        return

    print(f"Applying {len(pending)} migration(s) to {db_type}...")
    ok = 0
    for f in pending:
        if verbose: print(f"  → {f.name}")
        if apply_migration(conn, db_type, f, verbose=verbose):
            ok += 1
        else:
            print(f"  ✗ Stopped at {f.name}. Fix errors above and re-run.")
            conn.close()
            sys.exit(1)

    print(f"\n✓ Applied {ok} migration(s). Total applied: {len(applied) + ok}")
    conn.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Vurafya Migration Runner")
    parser.add_argument("--status", action="store_true", help="Show migration status")
    parser.add_argument("--quiet", action="store_true", help="Less verbose output")
    args = parser.parse_args()

    if args.status:
        # Simple status implementation
        conn, db_type = get_connection()
        applied = get_applied(conn, db_type)
        print(f"Database: {db_type}")
        print(f"Applied: {len(applied)}")
        conn.close()
    else:
        cmd_migrate(verbose=not args.quiet)
