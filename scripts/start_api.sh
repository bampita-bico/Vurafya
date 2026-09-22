#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DATABASE_URL="${DATABASE_URL:-postgresql://cdfd:change-me-postgres-password@localhost:5435/cdfd}"
export PYTHONPATH="$PWD"
exec ./venv/bin/python -m uvicorn backend.main:app --host 0.0.0.0 --port 8000
