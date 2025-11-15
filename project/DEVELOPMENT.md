# Development Guide

Полное руководство по разработке и развёртыванию Django AWS Boilerplate.

## 📑 Содержание

- [Быстрый старт](#быстрый-старт)
- [Переименование проекта](#переименование-проекта)
- [Локальная разработка](#локальная-разработка)
- [Работа с базой данных](#работа-с-базой-данных)
- [Тестирование](#тестирование)
- [Развёртывание на AWS](#развёртывание-на-aws)
- [Multi-tenant конфигурация](#multi-tenant-конфигурация)
- [CI/CD](#cicd)
- [Troubleshooting](#troubleshooting)

---

## Быстрый старт

### Предварительные требования

- **Docker** 20.10+
- **Docker Compose** v2.0+
- **Git**
- **GitHub CLI** (опционально, для создания репозитория из командной строки)
- **AWS CLI** (для deployment)

### Установка GitHub CLI (опционально)

```bash
# Ubuntu/Debian
sudo apt install gh

# macOS
brew install gh

# Или через snap
sudo snap install gh

# Авторизация
gh auth login
```

### Первый запуск

```bash
# 1. Клонируйте репозиторий
git clone https://github.com/YOUR_USERNAME/django-aws-boilerplate.git
cd django-aws-boilerplate

# 2. Настройте свой репозиторий (важно!)
# Удалите связь с исходным boilerplate репозиторием
rm -rf .git

# Инициализируйте новый git репозиторий
git init
git add .
git commit -m "Initial commit from django-aws-boilerplate"

# Вариант A: Создать репозиторий через GitHub CLI (рекомендуется)
gh repo create YOUR_PROJECT_NAME --private --source=. --remote=origin --push

# Вариант B: Вручную создать на GitHub и связать
# 1. Создайте репозиторий на https://github.com/new
# 2. Затем выполните:
git remote add origin https://github.com/YOUR_USERNAME/YOUR_PROJECT_NAME.git
git branch -M main
git push -u origin main

# 3. Запустите локальную среду
cd project
./scripts/dev/local-dev.sh

# 4. Откройте в браузере
open http://localhost/admin/
# Логин: admin
# Пароль: admin123
```

**Готово!** Приложение запущено и готово к разработке.

---

## Переименование проекта

По умолчанию Django проект называется `myapp`. Переименуйте перед началом работы:

### Автоматическое переименование

```bash
#!/bin/bash
OLD_NAME="myapp"
NEW_NAME="myproject"  # Ваше имя

cd project/src
mv "$OLD_NAME" "$NEW_NAME"

# Обновить все Python файлы
find . -type f -name "*.py" -exec sed -i "s/${OLD_NAME}\./${NEW_NAME}./g" {} +
find . -type f -name "*.py" -exec sed -i "s/${OLD_NAME} project/${NEW_NAME} project/g" {} +

# Обновить конфиги
cd ..
sed -i "s/${OLD_NAME}/${NEW_NAME}/g" src/Dockerfile
sed -i "s/${OLD_NAME}/${NEW_NAME}/g" src/pytest.ini  
sed -i "s/${OLD_NAME}/${NEW_NAME}/g" docker-compose.yml
sed -i "s/${OLD_NAME}/${NEW_NAME}/g" docker-compose.local.yml
sed -i "s/${OLD_NAME}/${NEW_NAME}/g" scripts/dev/make-command.sh

echo "✅ Проект переименован: $OLD_NAME → $NEW_NAME"
```

### Проверка

```bash
# Убедитесь что всё работает
./scripts/dev/local-dev.sh
```

---

## Локальная разработка

### Архитектура local environment

```
┌─────────────────┐
│   Browser       │
│ localhost:80    │
└────────┬────────┘
         │
    ┌────▼─────┐
    │  Nginx   │  (роутинг, статика)
    └────┬─────┘
         │
    ┌────▼─────┐
    │  Django  │  (runserver, hot-reload)
    │  :8000   │
    └────┬─────┘
         │
    ┌────▼─────┐
    │PostgreSQL│
    │  :5432   │
    └──────────┘
```

### Управление окружением

#### Запуск

```bash
cd project
./scripts/dev/local-dev.sh
```

Скрипт автоматически:
- ✅ Создаёт `.env.local` из шаблона
- ✅ Собирает Docker images
- ✅ Запускает все контейнеры
- ✅ Применяет миграции
- ✅ Создаёт superuser (admin/admin123)
- ✅ Собирает статику

#### Остановка

```bash
# Остановить (сохранить данные)
docker compose -f docker-compose.local.yml down

# Остановить и удалить volumes
docker compose -f docker-compose.local.yml down -v
```

#### Перезапуск после изменений

```bash
# Код Django - hot reload, ничего не нужно
# Изменения применяются автоматически

# requirements.txt изменён - rebuild
docker compose -f docker-compose.local.yml up --build -d django

# docker-compose.local.yml изменён - recreate
docker compose -f docker-compose.local.yml up -d --force-recreate
```

### Helper Scripts

#### 🐚 Database Shell

```bash
./scripts/dev/db-shell.sh

# Внутри PostgreSQL:
\l              # Список БД
\dt             # Список таблиц
\d table_name   # Структура таблицы
SELECT * FROM auth_user;
\q              # Выход
```

#### 🐍 Django Shell

```bash
./scripts/dev/django-shell.sh

# Внутри Django shell:
from django.contrib.auth.models import User
User.objects.all()
```

#### 🧪 Run Tests

```bash
# Все тесты
./scripts/dev/run-tests.sh

# С покрытием
./scripts/dev/run-tests.sh --cov

# Verbose
./scripts/dev/run-tests.sh -v

# Конкретный файл
./scripts/dev/run-tests.sh tests/test_basic.py

# Конкретный тест
./scripts/dev/run-tests.sh tests/test_basic.py::test_create_user -v
```

#### 📦 Load Fixtures

```bash
# Поместите fixtures в src/fixtures/
# Например: src/fixtures/users.json

./scripts/dev/load-fixtures.sh

# Загружает все .json файлы из src/fixtures/
```

#### 🛠️ Create Management Command

```bash
./scripts/dev/make-command.sh import_users

# Создаст: src/myapp/management/commands/import_users.py
# Запустить: python manage.py import_users
```

### Логи и отладка

#### Просмотр логов

```bash
# Все сервисы
docker compose -f docker-compose.local.yml logs -f

# Только Django
docker compose -f docker-compose.local.yml logs -f django

# Только PostgreSQL
docker compose -f docker-compose.local.yml logs -f postgres

# Последние 100 строк
docker compose -f docker-compose.local.yml logs --tail=100 django
```

#### Отладка с pdb

В коде добавьте:
```python
import pdb; pdb.set_trace()
```

Подключитесь к контейнеру:
```bash
docker attach myapp-django-local
# Нажмите Enter если prompt не появился
```

Отключиться: `Ctrl+P, Ctrl+Q` (не останавливает контейнер)

### Изменение кода

```
project/src/
├── myapp/              # Django проект
│   ├── settings.py     # Настройки
│   ├── urls.py         # URL routing
│   └── wsgi.py
├── your_app/           # Ваши приложения (создайте)
├── tests/              # Тесты
├── manage.py
└── requirements.txt
```

#### Создание нового app

```bash
docker compose -f docker-compose.local.yml exec django \
  python manage.py startapp your_app

# Добавьте в settings.py INSTALLED_APPS:
INSTALLED_APPS = [
    ...
    'your_app',
]
```

#### Миграции

```bash
# Создать миграции
docker compose -f docker-compose.local.yml exec django \
  python manage.py makemigrations

# Применить
docker compose -f docker-compose.local.yml exec django \
  python manage.py migrate

# Посмотреть SQL
docker compose -f docker-compose.local.yml exec django \
  python manage.py sqlmigrate your_app 0001
```

---

## Работа с базой данных

### Подключение

**Локальная разработка:**
```
Host: localhost
Port: 5432
Database: myapp
Username: myapp
Password: localdevpassword
```

**Инструменты:**
- pgAdmin
- DBeaver
- TablePlus
- psql (через db-shell.sh)

### Backup и Restore

#### Backup

```bash
docker compose -f docker-compose.local.yml exec postgres \
  pg_dump -U myapp myapp > backup.sql
```

#### Restore

```bash
cat backup.sql | docker compose -f docker-compose.local.yml exec -T postgres \
  psql -U myapp -d myapp
```

### Сброс базы данных

```bash
# ВНИМАНИЕ: Удаляет ВСЕ данные!
docker compose -f docker-compose.local.yml down -v
docker compose -f docker-compose.local.yml up -d postgres
sleep 5
docker compose -f docker-compose.local.yml up -d django

# Или через SQL
./scripts/dev/db-shell.sh
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
\q

# Затем применить миграции
docker compose -f docker-compose.local.yml exec django \
  python manage.py migrate
```

---

## Тестирование

### Структура тестов

```
src/tests/
├── __init__.py
├── conftest.py           # Fixtures
├── factories.py          # Factory Boy factories
├── test_basic.py         # Базовые тесты
└── your_app/
    ├── test_models.py
    ├── test_views.py
    └── test_api.py
```

### Запуск тестов

```bash
# Все тесты
./scripts/dev/run-tests.sh

# С покрытием
./scripts/dev/run-tests.sh --cov --cov-report=html
open htmlcov/index.html

# Только unit tests
./scripts/dev/run-tests.sh -m unit

# Только integration tests
./scripts/dev/run-tests.sh -m integration

# Быстрые тесты (без медленных)
./scripts/dev/run-tests.sh -m "not slow"
```

### Написание тестов

#### Использование fixtures (conftest.py)

```python
def test_user_creation(user):
    """user fixture создан в conftest.py"""
    assert user.username == "testuser"
    assert user.email == "test@example.com"

def test_api_call(api_client):
    """api_client - DRF APIClient"""
    response = api_client.get('/api/endpoint/')
    assert response.status_code == 200
```

#### Использование factories

```python
from tests.factories import UserFactory

def test_multiple_users():
    users = UserFactory.create_batch(5)
    assert User.objects.count() == 5
    
def test_admin_user():
    admin = UserFactory(is_staff=True, is_superuser=True)
    assert admin.is_superuser
```

#### Markers

```python
import pytest

@pytest.mark.unit
def test_model():
    pass

@pytest.mark.integration
def test_api():
    pass

@pytest.mark.slow
def test_heavy_operation():
    pass
```

---

## Развёртывание на AWS

### Предварительные требования

1. **AWS CLI** настроен
2. **AWS Account** с правами:
   - CloudFormation
   - EC2
   - S3
   - ECR
   - Secrets Manager
   - IAM
3. **EC2 Key Pair** создан

### Первое развёртывание

#### 1. Настройка AWS

```bash
# Настройте AWS CLI
aws configure --profile mycompany
# AWS Access Key ID: your-key
# AWS Secret Access Key: your-secret
# Default region: eu-west-1
# Default output format: json

# Проверка
aws sts get-caller-identity --profile mycompany
```

#### 2. Создайте EC2 Key Pair

```bash
aws ec2 create-key-pair \
  --key-name mycompany \
  --profile mycompany \
  --query 'KeyMaterial' \
  --output text > mycompany.pem

chmod 600 mycompany.pem
```

#### 3. Установите переменные окружения

```bash
export COMPANY_NAME=mycompany
export ADMIN_EMAIL_DOMAIN=mycompany.com
export AWS_PROFILE=mycompany
export DJANGO_PROJECT_NAME=myapp  # Если не переименовывали
```

Или создайте файл `company-config.sh`:

```bash
cp company-config.example.sh company-config-mycompany.sh
# Отредактируйте файл
source company-config-mycompany.sh
```

#### 4. Deploy Infrastructure

```bash
cd project

# Validate CloudFormation
./scripts/validate.sh

# Deploy stack
./scripts/deploy.sh dev

# Ждите ~5-10 минут
# CloudFormation создаст: VPC, EC2, Security Groups, S3, ECR
```

#### 5. Создайте Secrets Manager secrets

```bash
# Django superuser credentials
aws secretsmanager create-secret \
  --name mycompany/dev/django/superuser \
  --secret-string '{"username":"admin","email":"admin@mycompany.com","password":"YourSecurePassword123"}' \
  --profile mycompany

# Django SECRET_KEY
aws secretsmanager create-secret \
  --name mycompany/dev/django/secret_key \
  --secret-string "$(python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')" \
  --profile mycompany

# Database password
aws secretsmanager create-secret \
  --name mycompany/dev/db/password \
  --secret-string "$(openssl rand -base64 32)" \
  --profile mycompany
```

#### 6. Build и Push Docker Image

```bash
./scripts/build-image.sh dev

# Скрипт:
# - Логинится в ECR
# - Собирает image
# - Пушит в ECR
```

#### 7. Setup EC2 Instance

```bash
./scripts/setup-instance.sh dev

# Скрипт:
# - Подключается к EC2 через SSH
# - Устанавливает Docker
# - Логинится в ECR
# - Pull image
# - Создаёт .env файл
# - Запускает docker-compose
```

#### 8. Проверка

```bash
# Получите IP адрес
aws cloudformation describe-stacks \
  --stack-name mycompany-dev \
  --profile mycompany \
  --query 'Stacks[0].Outputs[?OutputKey==`InstancePublicIP`].OutputValue' \
  --output text

# Откройте в браузере
open http://<EC2_IP>/admin/

# Получите пароль admin
aws secretsmanager get-secret-value \
  --secret-id mycompany/dev/django/superuser \
  --profile mycompany \
  --query SecretString \
  --output text | jq -r '.password'
```

### Обновление приложения

```bash
# 1. Внесите изменения в код
# 2. Commit и push в git

# 3. Build новый image
./scripts/build-image.sh dev

# 4. Обновите на EC2
ssh -i mycompany.pem ec2-user@<EC2_IP>

cd /home/ec2-user/mycompany
docker compose pull
docker compose up -d

# Проверьте логи
docker compose logs -f django
```

### Удаление stack

```bash
# ВНИМАНИЕ: Удалит ВСЕ ресурсы!
./scripts/delete.sh dev

# Удалите также secrets вручную:
aws secretsmanager delete-secret \
  --secret-id mycompany/dev/django/superuser \
  --force-delete-without-recovery \
  --profile mycompany
```

---

## Multi-tenant конфигурация

Разверните изолированные окружения для разных клиентов/проектов.

### Концепция

Каждый клиент получает:
- ✅ Отдельный CloudFormation stack
- ✅ Отдельную EC2 instance
- ✅ Отдельный S3 bucket
- ✅ Отдельные secrets
- ✅ Отдельный ECR repository

### Пример: 2 клиента

#### Клиент 1: Acme Corp

```bash
# config/company-config-acme.sh
export COMPANY_NAME=acmecorp
export ADMIN_EMAIL_DOMAIN=acme.com
export AWS_PROFILE=acme

source config/company-config-acme.sh

# Deploy
./scripts/deploy.sh dev
./scripts/build-image.sh dev
./scripts/setup-instance.sh dev

# Ресурсы:
# Stack: acmecorp-dev
# S3: acmecorp-dev-media
# ECR: acmecorp-dev
# Secrets: acmecorp/dev/*
```

#### Клиент 2: Big Company

```bash
# config/company-config-bigco.sh
export COMPANY_NAME=bigco
export ADMIN_EMAIL_DOMAIN=bigcompany.com
export AWS_PROFILE=bigco

source config/company-config-bigco.sh

# Deploy
./scripts/deploy.sh dev
./scripts/build-image.sh dev
./scripts/setup-instance.sh dev

# Ресурсы:
# Stack: bigco-dev
# S3: bigco-dev-media
# ECR: bigco-dev
# Secrets: bigco/dev/*
```

### Переменные конфигурации

| Переменная | Описание | Пример |
|-----------|----------|--------|
| `COMPANY_NAME` | Префикс для всех ресурсов | `mycompany`, `client123` |
| `ADMIN_EMAIL_DOMAIN` | Домен для admin email | `example.com` |
| `AWS_PROFILE` | AWS CLI profile | `mycompany`, `default` |
| `DJANGO_PROJECT_NAME` | Имя Django проекта | `myapp`, `myproject` |

### Derived values (автоматические)

- Stack name: `${COMPANY_NAME}-${ENV}`
- S3 bucket: `${COMPANY_NAME}-${ENV}-media`
- ECR repo: `${COMPANY_NAME}-${ENV}`
- Secrets: `${COMPANY_NAME}/${ENV}/*`
- EC2 key: `${COMPANY_NAME}`

---

## CI/CD

### GitHub Actions Workflows

#### 1. PR Checks (`.github/workflows/pr-checks.yml`)

Запускается на каждый PR:
- ✅ Linting (black, isort, flake8)
- ✅ Tests (pytest)
- ✅ CloudFormation validation

#### 2. Deploy (`.github/workflows/deploy.yml`)

Запускается на push в main/develop:
1. **Lint** - code quality checks
2. **Test** - run pytest with PostgreSQL
3. **Build** - build и push Docker image в ECR
4. **Deploy** - deploy на AWS

### Настройка CI/CD

#### 1. GitHub Secrets

Добавьте в Settings → Secrets:

```
AWS_ACCESS_KEY_ID=your-key
AWS_SECRET_ACCESS_KEY=your-secret
AWS_REGION=eu-west-1
COMPANY_NAME=mycompany
```

#### 2. Environments

Создайте environments:
- `dev`
- `staging`
- `prod`

Для каждого добавьте:
- `AWS_ACCOUNT_ID`
- Approval rules (для prod)

#### 3. Branch protection

Main branch:
- ✅ Require PR reviews
- ✅ Require status checks (tests, lint)
- ✅ No force push

### Manual deploy trigger

```bash
# Через GitHub UI: Actions → Deploy → Run workflow
# Или через gh CLI:
gh workflow run deploy.yml -f environment=dev
```

---

## Troubleshooting

### Локальная разработка

#### Порт 80 занят

```bash
# Найдите процесс
sudo lsof -i :80

# Измените порт в docker-compose.local.yml
ports:
  - "8080:80"  # Вместо 80:80
```

#### Django не видит изменения кода

```bash
# Проверьте что volume монтирован
docker compose -f docker-compose.local.yml exec django ls -la /app

# Перезапустите Django
docker compose -f docker-compose.local.yml restart django
```

#### PostgreSQL connection refused

```bash
# Проверьте что PostgreSQL запущен
docker compose -f docker-compose.local.yml ps

# Проверьте логи
docker compose -f docker-compose.local.yml logs postgres

# Пересоздайте контейнер
docker compose -f docker-compose.local.yml up -d --force-recreate postgres
```

### AWS Deployment

#### CloudFormation stack failed

```bash
# Посмотрите events
aws cloudformation describe-stack-events \
  --stack-name mycompany-dev \
  --profile mycompany \
  --max-items 20

# Удалите failed stack
./scripts/delete.sh dev

# Попробуйте снова
./scripts/deploy.sh dev
```

#### Can't SSH to EC2

```bash
# Проверьте Security Group
aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=mycompany-dev-sg" \
  --profile mycompany

# Проверьте что используете правильный key
chmod 600 mycompany.pem
ssh -i mycompany.pem ec2-user@<IP> -v
```

#### Django admin login не работает

```bash
# Проверьте пароль в Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id mycompany/dev/django/superuser \
  --profile mycompany \
  --query SecretString \
  --output text

# Если пароль содержит спецсимволы, смените на простой:
aws secretsmanager update-secret \
  --secret-id mycompany/dev/django/superuser \
  --secret-string '{"username":"admin","email":"admin@example.com","password":"Admin123"}' \
  --profile mycompany

# Пересоздайте superuser на EC2
ssh -i mycompany.pem ec2-user@<IP>
cd /home/ec2-user/mycompany
docker compose exec django python create_superuser.py
```

#### Docker image pull failed

```bash
# Проверьте что ECR repo существует
aws ecr describe-repositories --profile mycompany

# Проверьте что image push прошёл успешно
aws ecr describe-images \
  --repository-name mycompany-dev \
  --profile mycompany

# На EC2: проверьте ECR login
aws ecr get-login-password | docker login --username AWS --password-stdin <ECR_URL>
```

---

## Полезные команды

### Docker

```bash
# Статус всех контейнеров
docker compose -f docker-compose.local.yml ps

# Использование ресурсов
docker stats

# Очистить неиспользуемые images
docker system prune -a

# Посмотреть volumes
docker volume ls

# Удалить всё (ОСТОРОЖНО!)
docker compose -f docker-compose.local.yml down -v
docker system prune -a --volumes
```

### Django

```bash
# Shell
docker compose -f docker-compose.local.yml exec django python manage.py shell

# Create superuser
docker compose -f docker-compose.local.yml exec django python manage.py createsuperuser

# Collect static
docker compose -f docker-compose.local.yml exec django python manage.py collectstatic

# Check deployment
docker compose -f docker-compose.local.yml exec django python manage.py check --deploy
```

### PostgreSQL

```bash
# Backup
docker compose -f docker-compose.local.yml exec postgres \
  pg_dump -U myapp myapp > backup_$(date +%Y%m%d).sql

# List connections
docker compose -f docker-compose.local.yml exec postgres \
  psql -U myapp -c "SELECT * FROM pg_stat_activity;"
```

---

## Дополнительные ресурсы

- **Django Documentation:** https://docs.djangoproject.com/
- **Docker Compose:** https://docs.docker.com/compose/
- **AWS CloudFormation:** https://docs.aws.amazon.com/cloudformation/
- **PostgreSQL:** https://www.postgresql.org/docs/

---

**Вопросы?** Создайте Issue на GitHub!
