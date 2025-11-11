#!/usr/bin/env bash
# Create a new Django management command

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

if [ $# -eq 0 ]; then
    echo "Usage: ./scripts/dev/make-command.sh <command_name>"
    echo "Example: ./scripts/dev/make-command.sh import_users"
    exit 1
fi

COMMAND_NAME="$1"

echo "🛠️  Creating Django management command: $COMMAND_NAME"
echo ""

docker compose -f docker-compose.local.yml exec django python manage.py startcommand "$COMMAND_NAME"

echo "✅ Command created at: src/autoakademia/management/commands/${COMMAND_NAME}.py"
