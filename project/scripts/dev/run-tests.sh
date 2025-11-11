#!/usr/bin/env bash
# Run Django tests

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo "🧪 Running tests..."
echo ""

# Run pytest inside Django container
docker compose -f docker-compose.local.yml exec django pytest "$@"

echo ""
echo "✅ Tests completed!"
