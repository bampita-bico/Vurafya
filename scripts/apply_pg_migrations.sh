#!/bin/bash
# Apply PostgreSQL migrations in order

DB_USER="cdfd"
DB_NAME="cdfd"
CONTAINER="vurafya_db"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MIGRATIONS_DIR="$PROJECT_ROOT/migrations_pg"

echo "Checking for schema_migrations table..."
docker exec -i $CONTAINER psql -U $DB_USER -d $DB_NAME -c "CREATE TABLE IF NOT EXISTS schema_migrations (id SERIAL PRIMARY KEY, filename VARCHAR(200) NOT NULL UNIQUE, applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"

for f in $(ls $MIGRATIONS_DIR/*.sql | sort); do
    filename=$(basename $f)

    # Check if already applied
    exists=$(docker exec -i $CONTAINER psql -U $DB_USER -d $DB_NAME -t -c "SELECT count(*) FROM schema_migrations WHERE filename = '$filename';" | tr -d '[:space:]')

    if [ "$exists" == "0" ]; then
        echo "Applying $filename..."
        docker exec -i $CONTAINER psql -U $DB_USER -d $DB_NAME < $f
        if [ $? -eq 0 ]; then
            docker exec -i $CONTAINER psql -U $DB_USER -d $DB_NAME -c "INSERT INTO schema_migrations (filename) VALUES ('$filename');"
        else
            echo "✗ Failed to apply $filename. Stopping."
            exit 1
        fi
    else
        echo "✓ Skipping $filename (already applied)"
    fi
done

echo "Done."
