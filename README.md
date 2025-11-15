# Django AWS Boilerplate

**Production-ready Django boilerplate** для быстрого старта проектов с развёртыванием на AWS.

## 🎯 Что это?

Готовый к использованию шаблон Django-приложения с полной инфраструктурой для разработки и развёртывания на AWS. Включает всё необходимое для старта нового проекта: от локальной разработки до production deployment.

## ✨ Возможности

### Локальная разработка
- 🐳 **Docker Compose** - полная среда разработки (PostgreSQL, Django, Nginx)
- 🔄 **Hot reload** - автоматическая перезагрузка при изменении кода
- 🧪 **Pytest** - настроенное тестирование с покрытием
- 🛠️ **Helper scripts** - скрипты для частых задач (миграции, shell, тесты)

### AWS Production
- ☁️ **CloudFormation** - инфраструктура как код (EC2, S3, ECR, Secrets Manager)
- 🔒 **Secrets Manager** - безопасное хранение credentials
- 📦 **ECR** - приватный Docker registry
- 🏢 **Multi-tenant** - изоляция ресурсов для разных клиентов/проектов

### CI/CD
- 🚀 **GitHub Actions** - автоматический deploy на push
- ✅ **Automated testing** - запуск тестов на каждый PR
- 🔍 **Code quality** - линтеры (black, isort, flake8)

## 🚀 Быстрый старт

### 1. Клонируйте репозиторий

```bash
git clone https://github.com/YOUR_USERNAME/django-aws-boilerplate.git my-project
cd my-project
```

### 2. Переименуйте проект (опционально)

По умолчанию Django проект называется `myapp`. Чтобы переименовать:

```bash
cd project/src
mv myapp myproject

# Обновите импорты
find . -type f -name "*.py" -exec sed -i 's/myapp\./myproject./g' {} +

# Обновите конфиги
cd ../..
sed -i 's/myapp/myproject/g' project/src/Dockerfile
sed -i 's/myapp/myproject/g' project/src/pytest.ini
sed -i 's/myapp/myproject/g' project/docker-compose*.yml
```

### 3. Запустите локальное окружение

```bash
cd project
./scripts/dev/local-dev.sh
```

Приложение будет доступно:
- **Веб-интерфейс:** http://localhost
- **Django Admin:** http://localhost/admin/ (admin/admin123)

### 4. Начните разработку

Подробная инструкция в [DEVELOPMENT.md](project/DEVELOPMENT.md)

## 📚 Документация

**[DEVELOPMENT.md](project/DEVELOPMENT.md)** - Полное руководство:
- Локальная разработка с Docker Compose
- Работа с базой данных
- Тестирование
- Развёртывание на AWS
- Multi-tenant конфигурация
- Все helper scripts

## 🛠️ Технологии

- **Backend:** Django 5.2, Python 3.14
- **Database:** PostgreSQL 16
- **Web Server:** Nginx (Alpine)
- **Containerization:** Docker, Docker Compose
- **Infrastructure:** AWS CloudFormation
- **CI/CD:** GitHub Actions
- **Testing:** Pytest, Coverage
- **Code Quality:** Black, isort, flake8

## 📦 Что включено

### Скрипты для разработки
```bash
./scripts/dev/local-dev.sh      # Запустить локальное окружение
./scripts/dev/db-shell.sh       # PostgreSQL shell
./scripts/dev/django-shell.sh   # Django shell
./scripts/dev/run-tests.sh      # Запустить тесты
./scripts/dev/load-fixtures.sh  # Загрузить fixtures
./scripts/dev/make-command.sh   # Создать management command
```

### Скрипты для deployment
```bash
./scripts/deploy.sh dev         # Deploy infrastructure
./scripts/build-image.sh dev    # Build и push Docker image
./scripts/setup-instance.sh dev # Setup EC2 instance
./scripts/validate.sh           # Validate CloudFormation
./scripts/delete.sh dev         # Delete stack
```

## 🔧 Конфигурация

### Переменные окружения

```bash
export COMPANY_NAME=mycompany           # Префикс для AWS ресурсов
export DJANGO_PROJECT_NAME=myapp        # Имя Django проекта
export ADMIN_EMAIL_DOMAIN=example.com   # Домен для admin email
```

### Multi-tenant deployment

```bash
# Клиент 1
export COMPANY_NAME=client1
./scripts/deploy.sh dev

# Клиент 2
export COMPANY_NAME=client2
./scripts/deploy.sh dev
```

## 📄 Структура проекта

```
.
├── README.md                   # Этот файл
├── project/
│   ├── DEVELOPMENT.md         # Полная документация
│   ├── cloudformation/        # AWS инфраструктура
│   ├── config/               # Конфигурация сервисов
│   ├── scripts/              # Все скрипты
│   ├── src/                 # Django приложение
│   │   ├── myapp/           # Django проект
│   │   ├── tests/
│   │   └── requirements.txt
│   ├── docker-compose.yml        # Production
│   └── docker-compose.local.yml  # Local development
└── .github/workflows/        # CI/CD
```

## 💡 Использование

Этот boilerplate идеален для:
- 🚀 Быстрого старта Django проектов
- 🏢 B2B SaaS приложений с multi-tenant архитектурой
- 📱 API backends
- 🌐 Web приложений с AWS hosting
- 🔧 Проектов с полной CI/CD автоматизацией

## 📝 License

MIT License - используйте свободно для коммерческих и некоммерческих проектов.

---

**Готово к использованию!** Просто клонируйте и начинайте разработку! 🎉

Полная документация → [DEVELOPMENT.md](project/DEVELOPMENT.md)
