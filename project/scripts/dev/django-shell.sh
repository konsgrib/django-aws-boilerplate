#!/usr/bin/env bash
# Open Django management shell

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo "🐍 Opening Django shell..."
echo ""

docker compose -f docker-compose.local.yml exec django python manage.py shell
