#!/usr/bin/env bash
# Vurafya Backend Startup Script
set -e

cd "$(dirname "$0")"

# Activate virtualenv if it exists
if [ -d "venv" ]; then
    source venv/bin/activate
fi

# Apply any pending migrations
echo "Checking migrations..."
python scripts/migrate.py --quiet

# Start server
echo "Starting Vurafya API..."
uvicorn backend.main:app \
    --host 0.0.0.0 \
    --port 8000 \
    --reload \
    --log-level info
