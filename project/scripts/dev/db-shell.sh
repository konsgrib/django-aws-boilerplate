#!/usr/bin/env bash
# Connect to PostgreSQL database shell

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo "🗄️  Connecting to PostgreSQL..."
echo ""

docker compose -f docker-compose.local.yml exec postgres psql -U myapp -d myapp
