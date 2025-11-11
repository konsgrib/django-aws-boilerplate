# Development Guide

Complete guide for local development and testing.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Development Workflow](#development-workflow)
- [Testing](#testing)
- [Database Management](#database-management)
- [Debugging](#debugging)
- [Code Quality](#code-quality)

---

## Prerequisites

### Required Software

- **Docker Desktop** (latest version)
- **Python 3.12+** (for local script execution)
- **Git**
- **Code Editor** (VS Code recommended)

### Optional Tools

- **PostgreSQL client** (for direct DB access)
- **AWS CLI** (for deployment)
- **Postman/HTTPie** (for API testing)

---

## Local Development Architecture

### Overview

Локальная разработка использует **отдельный** `docker-compose.local.yml`, полностью изолированный от AWS:

**Ключевые отличия от production:**

| Аспект | Production (AWS) | Local Development |
|--------|------------------|-------------------|
| **Секреты** | AWS Secrets Manager | Hardcoded в docker-compose |
| **БД** | PostgreSQL в Docker на EC2 | PostgreSQL контейнер локально |
| **Конфиги** | Загружаются из S3 | Монтируются из файлов |
| **Исходники** | В Docker image | Volume mount (live reload) |
| **Django server** | Gunicorn (production) | runserver (dev mode) |
| **Порты** | Только 80 (nginx) | 80 (nginx), 8000 (django), 5432 (postgres) |
| **S3/ECR** | Используется | Не нужно |

### Services Architecture

```
┌─────────────────────────────────────────┐
│  Browser: http://localhost              │
└────────────────┬────────────────────────┘
                 │
    ┌────────────▼────────────┐
    │  nginx:alpine           │  Port 80
    │  - Static files         │
    │  - Reverse proxy        │
    └────────────┬────────────┘
                 │
    ┌────────────▼────────────┐
    │  Django (runserver)     │  Port 8000
    │  - DEBUG=true           │
    │  - Auto-reload          │
    │  - Volume mounted code  │
    └────────────┬────────────┘
                 │
    ┌────────────▼────────────┐
    │  PostgreSQL 16          │  Port 5432
    │  - Local data volume    │
    │  - Accessible от host   │
    └─────────────────────────┘
```

### What Gets Started

**3 containers:**
1. **postgres** - База данных (exposed на localhost:5432)
2. **django** - Django с runserver (exposed на localhost:8000)
3. **nginx** - Reverse proxy (exposed на localhost:80)

**Volumes:**
- `postgres_data_local` - Данные БД (persistent)
- `static_volume_local` - Static files
- `media_volume_local` - Media uploads
- `./src:/app` - **Source code mount** (changes reflect instantly!)

---

## Quick Start

### 1. Clone Repository

```bash
git clone <repository-url>
cd django-aws-boilerplate
```

### 2. Start Local Environment

```bash
./project/scripts/dev/local-dev.sh
```

**Что происходит:**
1. ✅ Проверяет Docker
2. ✅ Создаёт `.env.local` из `.env.example` (если нет)
3. ✅ Останавливает старые контейнеры
4. ✅ Запускает PostgreSQL, Django, Nginx
5. ✅ Ждёт готовности PostgreSQL (health check)
6. ✅ Выполняет миграции
7. ✅ Создаёт superuser (admin/admin123)
8. ✅ Собирает static files
9. ✅ Запускает development server
10. ✅ Проверяет доступность через health endpoint

**Время запуска:** ~30-60 секунд

### 3. Access Application

- **Application**: http://localhost
- **Admin Panel**: http://localhost/admin/
  - Username: `admin`
  - Password: `admin123`
- **Health Check**: http://localhost/health/
- **Direct Django**: http://localhost:8000 (bypassing nginx)
- **PostgreSQL**: `localhost:5432` (credentials в docker-compose.local.yml)

---

## Development Workflow

### Typical Developer Day

**Утренний старт:**
```bash
# Запустить окружение
./project/scripts/dev/local-dev.sh

# Открыть в браузере
open http://localhost/admin/

# Открыть логи в отдельном окне
docker compose -f docker-compose.local.yml logs -f django
```

**Разработка фичи:**
```bash
# 1. Создать ветку
git checkout -b feature/new-feature

# 2. Открыть код в редакторе
code project/src/

# 3. Редактировать файлы (auto-reload работает!)
# project/src/myapp/views.py
# project/src/myapp/models.py

# 4. Если изменили модели - создать миграцию
docker compose -f docker-compose.local.yml exec django \
  python manage.py makemigrations

# 5. Применить миграцию
docker compose -f docker-compose.local.yml exec django \
  python manage.py migrate

# 6. Протестировать в браузере
open http://localhost/your-new-page/

# 7. Написать тесты
# project/src/tests/test_new_feature.py

# 8. Запустить тесты
./project/scripts/dev/run-tests.sh

# 9. Commit и push
git add .
git commit -m "feat: add new feature"
git push origin feature/new-feature
```

**Конец дня:**
```bash
# Остановить контейнеры (данные сохранятся)
docker compose -f docker-compose.local.yml down

# Или оставить работать
# (продолжите завтра с того же места)
```

### Project Structure

```
project/
├── src/                    # Django application code
│   ├── myapp/       # Main Django project
│   │   ├── settings.py     # Django settings
│   │   ├── urls.py         # URL routing
│   │   ├── views.py        # Views
│   │   └── wsgi.py         # WSGI config
│   ├── tests/              # Test files
│   │   ├── test_basic.py   # Sample tests
│   │   ├── factories.py    # Test data factories
│   │   └── conftest.py     # Pytest fixtures
│   ├── fixtures/           # Test data (JSON)
│   ├── requirements.txt    # Python dependencies
│   ├── manage.py           # Django management
│   ├── Dockerfile          # Docker image definition
│   └── .env.example        # Environment template
├── config/                 # Configuration files
│   ├── nginx/              # Nginx configs
│   │   ├── nginx.conf      # Main nginx config
│   │   └── autoakademia.conf # Site config
│   └── postgres/           # PostgreSQL init scripts
│       └── 01-init.sh      # DB initialization
├── scripts/
│   ├── dev/                # Development helper scripts
│   │   ├── local-dev.sh    # ⭐ Start local environment
│   │   ├── db-shell.sh     # PostgreSQL shell
│   │   ├── django-shell.sh # Django shell
│   │   └── run-tests.sh    # Run tests
│   ├── deploy.sh           # AWS deployment
│   ├── build-image.sh      # Build Docker image
│   └── setup-instance.sh   # Setup EC2 instance
├── cloudformation/         # AWS infrastructure
│   └── infrastructure/
│       └── resources.yaml  # CloudFormation template
└── docker-compose.local.yml # ⭐ Local development compose
```

### Making Code Changes

#### Python/Django Code Changes

1. **Edit code** in `src/` directory
2. **Changes are auto-reloaded** (Django runserver watches for changes)
3. **See changes instantly** - refresh browser
4. **View logs**: `docker compose -f docker-compose.local.yml logs -f django`

**Example:**
```python
# Edit src/myapp/views.py
def my_view(request):
    return HttpResponse("Hello World!")  # Save file → auto-reload!

# No need to restart! Just refresh browser.
```

#### Configuration Changes (nginx, docker-compose)

1. **Edit configuration file**
2. **Restart affected service**:

```bash
# Nginx config changed
docker compose -f docker-compose.local.yml restart nginx

# docker-compose.yml changed (need rebuild)
docker compose -f docker-compose.local.yml down
docker compose -f docker-compose.local.yml up -d --build
```

#### Requirements Changes

```bash
# Add package to src/requirements.txt
echo "django-extensions>=3.2.0" >> project/src/requirements.txt

# Rebuild Django container
docker compose -f docker-compose.local.yml build django
docker compose -f docker-compose.local.yml up -d django
```

### Adding Django Apps

```bash
# Create new app
docker compose -f docker-compose.local.yml exec django \
  python manage.py startapp myapp

# Don't forget to add to INSTALLED_APPS in settings.py
```

### Database Migrations

```bash
# Create migrations
docker compose -f docker-compose.local.yml exec django \
  python manage.py makemigrations

# Apply migrations
docker compose -f docker-compose.local.yml exec django \
  python manage.py migrate

# Show migration status
docker compose -f docker-compose.local.yml exec django \
  python manage.py showmigrations
```

---

## Testing

### Running All Tests

```bash
./project/scripts/dev/run-tests.sh
```

### Running Specific Tests

```bash
# Run specific test file
./project/scripts/dev/run-tests.sh tests/test_basic.py

# Run specific test class
./project/scripts/dev/run-tests.sh tests/test_basic.py::TestUserModel

# Run specific test method
./project/scripts/dev/run-tests.sh tests/test_basic.py::TestUserModel::test_create_user

# Run tests by marker
./project/scripts/dev/run-tests.sh -m unit       # Only unit tests
./project/scripts/dev/run-tests.sh -m integration # Only integration tests
```

### Coverage Reports

Coverage reports are generated automatically:
- **Terminal**: Shows in console after test run
- **HTML**: Open `src/htmlcov/index.html` in browser

### Writing Tests

Tests are located in `src/tests/`:

```python
import pytest
from tests.factories import UserFactory

@pytest.mark.unit
@pytest.mark.django_db
def test_user_creation():
    """Test user creation using factory"""
    user = UserFactory(username='testuser')
    assert user.username == 'testuser'
    assert user.is_active
```

**Test Markers:**
- `@pytest.mark.unit` - Fast unit tests
- `@pytest.mark.integration` - Integration tests
- `@pytest.mark.slow` - Slow tests (can be skipped)

---

## Database Management

### Access Database Shell

```bash
./project/scripts/dev/db-shell.sh
```

### Common PostgreSQL Commands

```sql
-- List all tables
\dt

-- Describe table structure
\d tablename

-- Show all users
SELECT * FROM auth_user;

-- Quit
\q
```

### Django Shell

```bash
./project/scripts/dev/django-shell.sh
```

```python
# Inside Django shell
from django.contrib.auth import get_user_model
User = get_user_model()

# Query users
users = User.objects.all()
admin = User.objects.get(username='admin')
```

### Reset Database

```bash
# Stop containers and remove volumes
docker compose -f docker-compose.local.yml down -v

# Restart (will recreate database)
./project/scripts/dev/local-dev.sh
```

### Load Test Data (Fixtures)

```bash
# Create fixtures from current data
docker compose -f docker-compose.local.yml exec django \
  python manage.py dumpdata auth.User --indent 2 > src/fixtures/users.json

# Load fixtures
./project/scripts/dev/load-fixtures.sh
```

---

## Debugging

### View Logs

```bash
# All services
docker compose -f docker-compose.local.yml logs -f

# Django only
docker compose -f docker-compose.local.yml logs -f django

# PostgreSQL only
docker compose -f docker-compose.local.yml logs -f postgres

# Last 50 lines
docker compose -f docker-compose.local.yml logs --tail=50 django
```

### Django Debug Toolbar (Optional)

Add to `requirements.txt`:
```
django-debug-toolbar>=4.2.0
```

Configure in `settings.py`:
```python
if DEBUG:
    INSTALLED_APPS += ['debug_toolbar']
    MIDDLEWARE += ['debug_toolbar.middleware.DebugToolbarMiddleware']
    INTERNAL_IPS = ['127.0.0.1', 'localhost']
```

### Python Debugger (pdb)

Add breakpoint in code:
```python
import pdb; pdb.set_trace()
```

Attach to container:
```bash
docker attach myapp-django-local
```

---

## Code Quality

### Linting

```bash
# Check code formatting
cd src
black --check .

# Auto-format code
black .

# Check import sorting
isort --check-only .

# Auto-sort imports
isort .

# Linting with flake8
flake8 . --max-line-length=120 --exclude=migrations
```

### Pre-commit Hooks (Recommended)

Install pre-commit:
```bash
pip install pre-commit
```

Create `.pre-commit-config.yaml`:
```yaml
repos:
  - repo: https://github.com/psf/black
    rev: 23.12.1
    hooks:
      - id: black
        language_version: python3.12
  
  - repo: https://github.com/pycqa/isort
    rev: 5.13.2
    hooks:
      - id: isort
  
  - repo: https://github.com/pycqa/flake8
    rev: 7.0.0
    hooks:
      - id: flake8
        args: ['--max-line-length=120']
```

Install hooks:
```bash
pre-commit install
```

---

## Helper Scripts Reference

All scripts are in `project/scripts/dev/`:

| Script | Description |
|--------|-------------|
| `local-dev.sh` | Start local development environment |
| `db-shell.sh` | Open PostgreSQL shell |
| `django-shell.sh` | Open Django management shell |
| `run-tests.sh` | Run pytest tests |
| `load-fixtures.sh` | Load test fixtures |
| `make-command.sh` | Create Django management command |

---

## Troubleshooting

### Port Already in Use

```bash
# Find process using port 80
sudo lsof -i :80

# Kill process
sudo kill -9 <PID>

# Or change port in docker-compose.local.yml:
# ports:
#   - "8080:80"
```

### Container Won't Start

```bash
# View detailed logs
docker compose -f docker-compose.local.yml logs

# Rebuild containers
docker compose -f docker-compose.local.yml build --no-cache
docker compose -f docker-compose.local.yml up
```

### Database Connection Issues

```bash
# Check PostgreSQL is running
docker compose -f docker-compose.local.yml ps

# Restart PostgreSQL
docker compose -f docker-compose.local.yml restart postgres

# Check database logs
docker compose -f docker-compose.local.yml logs postgres
```

### Docker Disk Space

```bash
# Clean up unused Docker resources
docker system prune -a

# Remove all volumes (⚠️  deletes data!)
docker volume prune
```

---

## Next Steps

- Read [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md) for AWS deployment
- See [MULTI_TENANT.md](MULTI_TENANT.md) for multi-tenant configuration
- Check [README.md](README.md) for production deployment

---

**Happy Coding! 🚀**
