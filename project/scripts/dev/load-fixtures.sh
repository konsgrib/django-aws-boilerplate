#!/usr/bin/env bash
# Load test fixtures into database

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo "📦 Loading fixtures..."
echo ""

# Check if fixtures directory exists
if [ ! -d "$PROJECT_ROOT/src/fixtures" ]; then
    echo "⚠️  No fixtures directory found at src/fixtures/"
    echo "Create fixtures with: python manage.py dumpdata > fixtures/mydata.json"
    exit 1
fi

# Load all fixtures
for fixture in "$PROJECT_ROOT/src/fixtures"/*.json; do
    if [ -f "$fixture" ]; then
        filename=$(basename "$fixture")
        echo "Loading $filename..."
        docker compose -f docker-compose.local.yml exec django python manage.py loaddata "fixtures/$filename"
    fi
done

echo ""
echo "✅ Fixtures loaded successfully!"
