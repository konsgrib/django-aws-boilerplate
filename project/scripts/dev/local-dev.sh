#!/usr/bin/env bash
# Local development environment startup script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo "========================================="
echo "🚀 Starting Local Development Environment"
echo "========================================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Check if .env.local exists
if [ ! -f "$PROJECT_ROOT/src/.env.local" ]; then
    echo "⚠️  No .env.local found in src/ directory"
    echo "Creating from .env.example..."
    if [ -f "$PROJECT_ROOT/src/.env.example" ]; then
        cp "$PROJECT_ROOT/src/.env.example" "$PROJECT_ROOT/src/.env.local"
        echo "✅ Created .env.local - please review and customize it"
    fi
fi

# Stop existing containers
echo ""
echo "🧹 Stopping existing containers..."
docker compose -f docker-compose.local.yml down

# Start services
echo ""
echo "🐳 Starting services..."
docker compose -f docker-compose.local.yml up -d

# Wait for services to be healthy
echo ""
echo "⏳ Waiting for services to be healthy..."
sleep 5

# Check status
echo ""
echo "📊 Service Status:"
docker compose -f docker-compose.local.yml ps

# Wait for Django to be ready
echo ""
echo "⏳ Waiting for Django to be ready..."
max_attempts=30
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if curl -s http://localhost/health/ > /dev/null 2>&1; then
        echo "✅ Django is ready!"
        break
    fi
    attempt=$((attempt + 1))
    echo -n "."
    sleep 2
done

if [ $attempt -eq $max_attempts ]; then
    echo ""
    echo "⚠️  Django didn't respond in time. Check logs with:"
    echo "   docker compose -f docker-compose.local.yml logs django"
fi

echo ""
echo "========================================="
echo "✅ Local Development Environment Ready!"
echo "========================================="
echo ""
echo "🌐 Application: http://localhost"
echo "🔐 Admin Panel: http://localhost/admin/"
echo "   Username: admin"
echo "   Password: admin123"
echo ""
echo "📊 Useful commands:"
echo "   View logs:        docker compose -f docker-compose.local.yml logs -f"
echo "   Stop services:    docker compose -f docker-compose.local.yml down"
echo "   Django shell:     ./scripts/dev/django-shell.sh"
echo "   Database shell:   ./scripts/dev/db-shell.sh"
echo "   Run tests:        ./scripts/dev/run-tests.sh"
echo ""
