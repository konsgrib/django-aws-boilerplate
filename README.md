# Django AWS Boilerplate

Production-ready Django boilerplate for AWS deployment with Docker, CloudFormation, and CI/CD.

## ✨ Features

- 🐳 **Docker-based** - Nginx + Django + PostgreSQL
- ☁️ **AWS Infrastructure** - CloudFormation templates for EC2, S3, ECR, Secrets Manager
- 🏢 **Multi-tenant Ready** - Deploy isolated stacks for multiple companies/clients
- 🔒 **Security First** - AWS Secrets Manager, SSM Parameter Store, IAM roles
- 🚀 **CI/CD Pipeline** - GitHub Actions with automated testing and deployment
- 🧪 **Testing Setup** - Pytest, coverage, factories, fixtures
- 💻 **Local Development** - Full Docker Compose environment without AWS dependencies
- 📚 **Comprehensive Documentation** - Setup, deployment, development, contributing guides

## 🚀 Quick Start

### For New Projects

```bash
# 1. Clone this boilerplate
git clone https://github.com/YOUR_USERNAME/django-aws-boilerplate.git my-project
cd my-project

# 2. Start local development
./project/scripts/dev/local-dev.sh

# 3. Access application
# App: http://localhost
# Admin: http://localhost/admin/ (admin/admin123)
```

### For AWS Deployment

```bash
# 1. Configure AWS CLI
aws configure --profile mycompany

# 2. Set company name
export COMPANY_NAME=mycompany
export ADMIN_EMAIL_DOMAIN=mycompany.com

# 3. Create EC2 key pair
aws ec2 create-key-pair --key-name mycompany \
  --query 'KeyMaterial' --output text > mycompany.pem
chmod 600 mycompany.pem

# 4. Deploy infrastructure
cd project
./scripts/deploy.sh dev
./scripts/build-image.sh dev
./scripts/setup-instance.sh dev
```

## 📚 Documentation

- **[DEVELOPMENT.md](project/DEVELOPMENT.md)** - Local development setup and workflows
- **[DEPLOYMENT_CHECKLIST.md](project/DEPLOYMENT_CHECKLIST.md)** - Step-by-step deployment guide  
- **[MULTI_TENANT.md](project/MULTI_TENANT.md)** - Multi-tenant configuration
- **[DJANGO_ADMIN.md](project/DJANGO_ADMIN.md)** - Admin credentials management
- **[CONTRIBUTING.md](project/CONTRIBUTING.md)** - Contributing guidelines

## 🏗️ Architecture

```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │
┌──────▼──────┐
│   Nginx     │ (reverse proxy)
└──────┬──────┘
       │
┌──────▼──────┐
│   Django    │ (Gunicorn)
│  + Gunicorn │
└──────┬──────┘
       │
┌──────▼──────┐
│ PostgreSQL  │
└─────────────┘
```

**AWS Infrastructure:**
- **EC2** (t3.micro) - Application server
- **S3** - Configuration files and media storage
- **ECR** - Docker image registry
- **Secrets Manager** - Secure credential storage
- **SSM Parameter Store** - Configuration management
- **CloudFormation** - Infrastructure as Code

## 🛠️ Technology Stack

- **Backend**: Django 5.2, Python 3.14
- **Database**: PostgreSQL 16
- **Server**: Gunicorn + Nginx
- **Container**: Docker + Docker Compose
- **Cloud**: AWS (EC2, S3, ECR, Secrets Manager, SSM)
- **IaC**: AWS CloudFormation
- **CI/CD**: GitHub Actions
- **Testing**: Pytest, pytest-django, factory-boy

## 📦 What's Included

### Local Development
- `docker-compose.local.yml` - No AWS dependencies
- Helper scripts for Django/DB shells
- Auto-reload development server
- Pytest configuration with coverage

### AWS Deployment
- CloudFormation templates
- Deployment automation scripts
- Multi-tenant support
- Secrets management
- Automated backups configuration

### CI/CD
- Automated testing on PR
- Code quality checks (black, flake8, isort)
- Automated deployment to dev/staging/prod
- Health check verification

### Testing
- Unit test examples
- Integration test examples
- Test factories with faker
- Coverage configuration

## 🔧 Customization

### 1. Rename Project

```bash
# Update Django project name
mv project/src/autoakademia project/src/YOUR_PROJECT_NAME

# Update in project/scripts/includes.sh
DJANGO_PROJECT_NAME=YOUR_PROJECT_NAME

# Update settings path in project/src/manage.py
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'YOUR_PROJECT_NAME.settings')
```

### 2. Add Your Apps

```bash
# Inside Django container
docker compose -f docker-compose.local.yml exec django \
  python manage.py startapp your_app

# Add to INSTALLED_APPS in settings.py
```

### 3. Configure for Your Company

```bash
# Set environment variables
export COMPANY_NAME=yourcompany
export ADMIN_EMAIL_DOMAIN=yourcompany.com
export AWS_PROFILE=yourcompany

# Or create company-config.sh
cp project/company-config.example.sh company-config.sh
# Edit company-config.sh
source company-config.sh
```

## 🧪 Running Tests

```bash
# All tests
./project/scripts/dev/run-tests.sh

# Specific tests
./project/scripts/dev/run-tests.sh tests/test_myfeature.py

# With coverage
./project/scripts/dev/run-tests.sh --cov
```

## 📝 Project Structure

```
.
├── project/
│   ├── src/                    # Django application
│   ├── config/                 # nginx, postgres configs
│   ├── scripts/                # Deployment and dev scripts
│   ├── cloudformation/         # AWS CloudFormation templates
│   ├── .github/workflows/      # CI/CD pipelines
│   └── docker-compose.local.yml
├── .gitignore
└── README.md
```

## 🤝 Contributing

See [CONTRIBUTING.md](project/CONTRIBUTING.md) for development guidelines.

## 📄 License

This boilerplate is open source. Feel free to use it for your projects.

## 🙏 Credits

Built with Django, AWS, Docker, and love ❤️

---

**Ready to build your next Django project on AWS? Let's go! 🚀**
