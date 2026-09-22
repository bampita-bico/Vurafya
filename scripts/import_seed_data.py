#!/usr/bin/env python3
"""Deprecated SQLite seed importer.

Vurafya now seeds PostgreSQL only. Run:
  DATABASE_URL=postgresql://... python scripts/import_seed_postgres.py
"""

import sys


if __name__ == "__main__":
    print(__doc__)
    sys.exit(1)
