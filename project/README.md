# Django AWS Deployment

Production-ready Django deployment на AWS с использованием Docker, CloudFormation и полной изоляцией ресурсов для мультитенантности.

## 📚 Documentation

- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Local development setup and workflows
- **[DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)** - Step-by-step deployment guide
- **[MULTI_TENANT.md](MULTI_TENANT.md)** - Multi-tenant configuration
- **[DJANGO_ADMIN.md](DJANGO_ADMIN.md)** - Admin credentials and management

---

## 🚀 Quick Start (Local Development)

```bash
# 1. Clone repository
git clone <repository-url>
cd django-aws-boilerplate

# 2. Start local development environment
./project/scripts/dev/local-dev.sh

# 3. Access application
# Application: http://localhost
# Admin: http://localhost/admin/ (admin/admin123)
```

See [DEVELOPMENT.md](DEVELOPMENT.md) for detailed local development guide.

---

## 🌐 Quick Start (AWS Production)

```bash
# 1. Настройте AWS CLI
aws configure --profile mycompany

# 2. Создайте EC2 key pair
aws ec2 create-key-pair --key-name mycompany \
  --query 'KeyMaterial' --output text > ../mycompany.pem
chmod 600 ../mycompany.pem

# 3. Деплой инфраструктуры и приложения
cd project
./scripts/deploy.sh dev
./scripts/build-image.sh dev
./scripts/setup-instance.sh dev

# 4. Получите admin пароль
aws secretsmanager get-secret-value \
  --secret-id mycompany/dev/django/superuser \
  --query SecretString --output text | jq -r '.password'

# 5. Откройте приложение
aws cloudformation describe-stacks --stack-name mycompany-dev \
  --query "Stacks[0].Outputs[?OutputKey=='PublicIP'].OutputValue" --output text
# Перейдите на http://<IP>/admin/
```

## Архитектура

- **EC2**: t3.micro instance (Amazon Linux 2023)
- **Контейнеры**: Nginx + Django + PostgreSQL
- **Хранилище**: S3 для конфигов и медиа
- **Секреты**: AWS Secrets Manager + SSM Parameter Store
- **Образы**: Amazon ECR

## Multi-Tenant Configuration

Проект поддерживает деплой для разных компаний/клиентов с полной изоляцией ресурсов.

**Настройка через переменные окружения** (файл `company-config.example.sh`):

```bash
export COMPANY_NAME=mycompany              # Префикс для всех AWS ресурсов
export ADMIN_EMAIL_DOMAIN=mycompany.com    # Домен для admin email
export AWS_PROFILE=mycompany               # AWS CLI профиль
```

**Все ресурсы создаются с префиксом `COMPANY_NAME`:**
- CloudFormation Stack: `mycompany-dev`
- S3 Bucket: `mycompany-dev-media`
- Secrets: `mycompany/dev/django/SECRET_KEY`
- EC2 Key: `mycompany.pem`

**Документация:**
- [company-config.example.sh](company-config.example.sh) - Пример конфигурации переменных
- [MULTI_TENANT.md](MULTI_TENANT.md) - Полное руководство по мультитенантности
- [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md) - Чеклист для деплоя

## Структура проекта

```
project/
├── cloudformation/infrastructure/resources.yaml  # CloudFormation шаблон
├── config/
│   ├── nginx/                                    # Nginx конфигурация
│   └── postgres/                                 # PostgreSQL init скрипты
├── scripts/
│   ├── includes.sh                               # Переменные и функции
│   ├── validate.sh                               # Валидация CloudFormation
│   ├── deploy.sh                                 # Деплой инфраструктуры
│   ├── build-image.sh                            # Сборка Docker образа
│   ├── setup-instance.sh                         # Настройка приложения на EC2
│   └── delete.sh                                 # Удаление стека
├── src/                                          # Django приложение
├── docker-compose.yml                            # Оркестрация контейнеров
├── .env.example                                  # Пример переменных окружения
├── company-config.example.sh                     # Пример конфигурации компании
├── MULTI_TENANT.md                               # Руководство по мультитенантности
├── DEPLOYMENT_CHECKLIST.md                       # Чеклист деплоя
├── DJANGO_ADMIN.md                               # Доступ к Django admin
└── README.md                                     # Основная документация
```

## Предварительные требования

1. **AWS CLI** настроен с credentials:
   ```bash
   aws configure --profile mycompany
   # Введите: Access Key, Secret Key, Region (eu-west-1)
   ```

2. **EC2 Key Pair** создан в AWS:
   ```bash
   aws ec2 create-key-pair \
     --key-name mycompany \
     --query 'KeyMaterial' \
     --output text > ../mycompany.pem
   chmod 600 ../mycompany.pem
   ```

3. **Docker** установлен локально для сборки образов

4. **(Опционально) Настройка для другой компании**:
   ```bash
   # Создайте файл конфигурации
   cp company-config.example.sh company-mycompany.sh
   
   # Отредактируйте переменные
   export COMPANY_NAME=mycompany
   export ADMIN_EMAIL_DOMAIN=mycompany.com
   export AWS_PROFILE=mycompany
   
   # Загрузите конфигурацию
   source company-mycompany.sh
   ```

## Полный процесс деплоя

### 1. Валидация шаблона

```bash
cd project
./scripts/validate.sh
```

Проверяет CloudFormation template на ошибки синтаксиса.

### 2. Сборка и пуш Docker образа в ECR

```bash
# По умолчанию для dev окружения
./scripts/build-image.sh

# Для production
./scripts/build-image.sh prod
```

Эта команда:
- Создает ECR репозиторий (если не существует)
- Собирает Docker образ
- Пушит образ в ECR с тегом `latest`

### 3. Деплой CloudFormation стека (инфраструктура)

```bash
# Dev окружение (по умолчанию)
./scripts/deploy.sh

# Production окружение
./scripts/deploy.sh prod
```

Создает:
- EC2 инстанс с Docker
- S3 bucket для конфигов
- Security Groups (22, 80, 443)
- IAM роли с доступом к S3, Secrets Manager, SSM
- Secrets Manager секреты (Django SECRET_KEY, DB credentials)
- SSM параметры (DEBUG, ALLOWED_HOSTS, S3_BUCKET)

**Важно**: После деплоя дождитесь завершения UserData скрипта (~5-10 минут)

### 4. Настройка приложения на EC2

```bash
# Загружает конфиги в S3, подключается по SSH, запускает docker-compose
./scripts/setup-instance.sh

# Для production
./scripts/setup-instance.sh prod

# Для production
./scripts/setup-instance.sh prod
```

Этот скрипт:
- Загружает конфиги в S3
- Подключается по SSH к EC2
- Скачивает конфиги из S3
- Настраивает .env файл из Secrets Manager/SSM
- Логинится в ECR
- Запускает docker-compose up -d
- Выполняет миграции Django
- Проверяет health endpoint

### 5. Получение учетных данных администратора

```bash
# Получить пароль superuser из AWS Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id mycompany/dev/django/superuser \
  --query SecretString \
  --output text | jq '.'

# Для другой компании используйте ${COMPANY_NAME}
aws secretsmanager get-secret-value \
  --secret-id ${COMPANY_NAME}/dev/django/superuser \
  --query SecretString --output text | jq '.'
```

Выведет:
```json
{
  "username": "admin",
  "email": "admin@example.com",
  "password": "RandomPassword123"
}
```

### 6. Проверка приложения

```bash
# Получить IP адрес EC2
STACK_NAME=${COMPANY_NAME:-mycompany}-dev
EC2_IP=$(aws cloudformation describe-stacks \
  --stack-name ${STACK_NAME} \
  --query "Stacks[0].Outputs[?OutputKey=='PublicIP'].OutputValue" \
  --output text)

echo "Application URL: http://${EC2_IP}"
echo "Admin URL: http://${EC2_IP}/admin/"

# Проверить health endpoint
curl http://${EC2_IP}/health

# Проверить админку (должен редирект на login)
curl -I http://${EC2_IP}/admin/
```

### 7. SSH подключение и логи

```bash
# Подключиться к EC2
KEY_NAME=${COMPANY_NAME:-mycompany}
APP_DIR=/home/ec2-user/${COMPANY_NAME:-mycompany}

ssh -i ../${KEY_NAME}.pem ec2-user@${EC2_IP}

# После подключения:
cd ${APP_DIR}
docker compose ps              # Статус контейнеров
docker compose logs -f         # Все логи
docker compose logs django     # Только Django
docker compose logs nginx      # Только Nginx
docker compose logs postgres   # Только PostgreSQL
```

## Обновление приложения

### Обновление кода Django

```bash
# 1. Пересобрать и загрузить образ
./scripts/build-image.sh dev

# 2. На EC2 перезапустить контейнер с новым образом
KEY_NAME=${COMPANY_NAME:-mycompany}
APP_DIR=/home/ec2-user/${COMPANY_NAME:-mycompany}
STACK_NAME=${COMPANY_NAME:-mycompany}-dev
EC2_IP=$(aws cloudformation describe-stacks --stack-name ${STACK_NAME} \
  --query "Stacks[0].Outputs[?OutputKey=='PublicIP'].OutputValue" --output text)

ssh -i ../${KEY_NAME}.pem ec2-user@${EC2_IP} <<EOF
cd ${APP_DIR}
docker compose pull django
docker compose up -d django
docker compose exec -T django python manage.py migrate
docker compose exec -T django python manage.py collectstatic --noinput
EOF
```

### Обновление конфигураций (nginx, postgres)

```bash
# Использовать переменные для мультитенантности
S3_BUCKET=${COMPANY_NAME:-mycompany}-dev-media
APP_DIR=/home/ec2-user/${COMPANY_NAME:-mycompany}

# 1. Загрузить новые конфиги в S3
aws s3 sync ./config/nginx s3://${S3_BUCKET}/config/nginx/ --delete
aws s3 sync ./config/postgres s3://${S3_BUCKET}/config/postgres/ --delete

# 2. На EC2 скачать и перезапустить
ssh -i ../${KEY_NAME}.pem ec2-user@${EC2_IP} <<EOF
cd ${APP_DIR}
aws s3 sync s3://${S3_BUCKET}/config/nginx/ ./config/nginx/
aws s3 sync s3://${S3_BUCKET}/config/postgres/ ./config/postgres/
docker compose restart nginx
EOF
```

### Обновление инфраструктуры (CloudFormation)

```bash
# Изменить resources.yaml и задеплоить изменения
./scripts/deploy.sh dev

# CloudFormation обновит только измененные ресурсы
# EC2 instance не будет пересоздан если не менялись его параметры
```

## Деплой для другой компании

Полная изоляция ресурсов для мультитенантности:

```bash
# 1. Создайте конфигурацию для новой компании
export COMPANY_NAME=newcompany
export ADMIN_EMAIL_DOMAIN=newcompany.com
export AWS_PROFILE=newcompany

# 2. Создайте EC2 key pair
aws ec2 create-key-pair --key-name newcompany \
  --query 'KeyMaterial' --output text > ../newcompany.pem
chmod 600 ../newcompany.pem

# 3. Деплой (все ресурсы будут с префиксом 'newcompany')
./scripts/deploy.sh dev
./scripts/build-image.sh dev
./scripts/setup-instance.sh dev

# 4. Получите credentials
aws secretsmanager get-secret-value \
  --secret-id newcompany/dev/django/superuser \
  --query SecretString --output text | jq '.'
```

**Результат**: Все ресурсы создаются изолированно:
- Stack: `newcompany-dev`
- S3: `newcompany-dev-media`
- Secrets: `newcompany/dev/*`
- ECR: `newcompany-dev`

См. подробную документацию: [MULTI_TENANT.md](MULTI_TENANT.md)

## Удаление стека

```bash
# For your company (mycompany)
./scripts/delete.sh dev

# Для другой компании
export COMPANY_NAME=oldcompany
export AWS_PROFILE=oldcompany
./scripts/delete.sh dev
```

**Важно**: 
- S3 bucket с версионированием нужно очистить вручную перед удалением
- ECR репозиторий будет удален со всеми образами
- Secrets Manager секреты можно восстановить в течение 7-30 дней

```bash
# Очистить S3 перед удалением стека
aws s3 rm s3://${COMPANY_NAME}-dev-media --recursive
```

## Переменные окружения

**На локальной машине**: задаются через `export` или файл конфигурации
**На EC2**: генерируются автоматически из AWS Secrets Manager и SSM Parameter Store

Ключевые переменные:
- `COMPANY_NAME` - префикс для всех ресурсов (default: `mycompany`)
- `ADMIN_EMAIL_DOMAIN` - домен для admin email (default: `example.com`)
- `AWS_PROFILE` - AWS CLI профиль (default: `mycompany`)
- `DJANGO_PROJECT_NAME` - имя Django проекта в src/ (default: `mycompany`)

Секреты хранятся в:
- **Secrets Manager**: `${COMPANY_NAME}/{env}/django/SECRET_KEY`, `${COMPANY_NAME}/{env}/database/credentials`, `${COMPANY_NAME}/{env}/django/superuser`
- **SSM Parameter Store**: `/${COMPANY_NAME}/{env}/app/*`, `/${COMPANY_NAME}/{env}/ssh/*`

## Окружения

Поддерживаются 3 окружения:
- **dev** (по умолчанию)
- **stag**
- **prod**

Каждое окружение создает отдельные ресурсы:
- Stack: `mycompany-{env}`
- S3: `mycompany-{env}-media`
- Секреты: `mycompany/{env}/*`

## Полезные команды

```bash
# Проверить статус стека
aws cloudformation describe-stacks --stack-name mycompany-dev

# Посмотреть события деплоя
aws cloudformation describe-stack-events --stack-name mycompany-dev

# Подключиться к EC2
ssh -i mycompany.pem ec2-user@<EC2_IP>

# Логи контейнеров
docker-compose logs -f django
docker-compose logs -f nginx
docker-compose logs -f postgres

# Перезапустить все контейнеры
docker-compose restart

# Выполнить команду Django
docker-compose exec django python manage.py createsuperuser
docker-compose exec django python manage.py shell
```

## Security & Secrets Management

All sensitive credentials are managed by AWS Secrets Manager:

- **Django SECRET_KEY**: 64-character random string
- **Database Password**: 32-character random string
- **Superuser Password**: 16-character random string

**Password Policy**: All generated passwords exclude special characters that can cause issues:
- Excluded: `"@/\<>%` ` |&;$` and punctuation
- Only alphanumeric characters used for reliability

**Access Django Admin**:
```bash
# Get superuser credentials
aws secretsmanager get-secret-value \
  --secret-id mycompany/dev/django/superuser \
  --query SecretString --output text | jq '.'
```

See [DJANGO_ADMIN.md](DJANGO_ADMIN.md) for complete admin access documentation.

## Troubleshooting

### UserData не завершился

```bash
ssh -i mycompany.pem ec2-user@<EC2_IP>
tail -f /var/log/userdata.log
```

### Контейнеры не запускаются

```bash
ssh -i mycompany.pem ec2-user@<EC2_IP>
cd /home/ec2-user/mycompany
docker-compose ps
docker-compose logs
```

### Проблемы с ECR

```bash
# Проверить существование образа
aws ecr describe-images --repository-name mycompany-dev

# Пересобрать и загрузить
./scripts/build-image.sh
```

### Django миграции failed

```bash
ssh -i mycompany.pem ec2-user@<EC2_IP>
cd /home/ec2-user/mycompany
docker-compose exec django python manage.py migrate --fake-initial
```

## Документация

| Файл | Описание |
|------|----------|
| [README.md](README.md) | Основная документация и быстрый старт |
| [MULTI_TENANT.md](MULTI_TENANT.md) | Полное руководство по мультитенантному деплою |
| [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md) | Пошаговый чеклист для деплоя |
| [DJANGO_ADMIN.md](DJANGO_ADMIN.md) | Доступ к Django admin, смена пароля, troubleshooting |
| [company-config.example.sh](company-config.example.sh) | Пример конфигурации переменных для компании |
| [.env.example](.env.example) | Пример переменных окружения для приложения |

## Лицензия

Proprietary
