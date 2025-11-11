# Contributing Guide

Thank you for considering contributing to this project! 🎉

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Submitting Changes](#submitting-changes)
- [Coding Standards](#coding-standards)
- [Testing Requirements](#testing-requirements)

---

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on the problem, not the person
- Help others learn and grow

---

## Getting Started

### 1. Fork & Clone

```bash
# Fork the repository on GitHub, then:
git clone https://github.com/YOUR_USERNAME/autoakademia-aws.git
cd autoakademia-aws
```

### 2. Set Up Development Environment

```bash
# Start local development environment
./project/scripts/dev/local-dev.sh
```

See [DEVELOPMENT.md](DEVELOPMENT.md) for detailed setup instructions.

### 3. Create Feature Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/bug-description
```

**Branch Naming Convention:**
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Test additions/improvements

---

## Development Workflow

### 1. Make Changes

- Write clean, readable code
- Follow [PEP 8](https://pep8.org/) style guide
- Add docstrings to functions/classes
- Keep changes focused and atomic

### 2. Run Tests

```bash
# Run all tests
./project/scripts/dev/run-tests.sh

# Run specific tests
./project/scripts/dev/run-tests.sh tests/test_myfeature.py
```

### 3. Check Code Quality

```bash
cd project/src

# Format code
black .
isort .

# Lint code
flake8 . --max-line-length=120 --exclude=migrations
```

### 4. Test Locally

```bash
# Test your changes work
./project/scripts/dev/local-dev.sh

# Verify in browser
open http://localhost
```

---

## Submitting Changes

### 1. Commit Guidelines

**Commit Message Format:**
```
<type>: <subject>

<body>

<footer>
```

**Types:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting)
- `refactor:` Code refactoring
- `test:` Test additions/changes
- `chore:` Build process, tooling changes

**Example:**
```
feat: add user profile page

- Add profile model
- Create profile view and template
- Add tests for profile functionality

Closes #123
```

### 2. Push Changes

```bash
git add .
git commit -m "feat: your feature description"
git push origin feature/your-feature-name
```

### 3. Create Pull Request

1. Go to GitHub repository
2. Click "New Pull Request"
3. Select your branch
4. Fill in PR template:
   - Description of changes
   - Related issues
   - Testing done
   - Screenshots (if UI changes)

### 4. PR Review Process

- CI/CD checks must pass
- At least one review required
- Address reviewer feedback
- Keep PR focused and small (<500 lines)

---

## Coding Standards

### Python Style

- **PEP 8** compliance
- **Line length**: 120 characters max
- **Imports**: Sorted with `isort`
- **Formatting**: Auto-formatted with `black`

### Django Best Practices

```python
# Use class-based views when appropriate
from django.views.generic import ListView

class UserListView(ListView):
    model = User
    template_name = 'users/list.html'

# Use model managers for complex queries
class ActiveUserManager(models.Manager):
    def get_queryset(self):
        return super().get_queryset().filter(is_active=True)

# Add docstrings
def complex_function(param):
    """
    Brief description of function.
    
    Args:
        param: Description of parameter
    
    Returns:
        Description of return value
    """
    pass
```

### Database Migrations

```bash
# Always create migration files
python manage.py makemigrations

# Check migration SQL before applying
python manage.py sqlmigrate app_name 0001

# Add migration to git
git add */migrations/*.py
```

### Configuration

- **Never commit secrets**
- Use environment variables
- Document new settings in `.env.example`
- Add to CloudFormation if AWS resource

---

## Testing Requirements

### Test Coverage

- Aim for **>80% coverage**
- All new features must have tests
- Bug fixes should include regression tests

### Writing Tests

```python
import pytest
from tests.factories import UserFactory

@pytest.mark.unit
@pytest.mark.django_db
def test_user_creation():
    """Test user can be created"""
    user = UserFactory(username='testuser')
    assert user.username == 'testuser'

@pytest.mark.integration
@pytest.mark.django_db
def test_user_login_flow(api_client):
    """Test complete user login flow"""
    user = UserFactory()
    response = api_client.post('/login/', {
        'username': user.username,
        'password': 'password123'
    })
    assert response.status_code == 200
```

### Test Types

- **Unit tests**: Test individual functions/methods
- **Integration tests**: Test multiple components together
- **E2E tests**: Test complete user workflows

### Running Tests

```bash
# All tests
./project/scripts/dev/run-tests.sh

# Unit tests only
./project/scripts/dev/run-tests.sh -m unit

# With coverage
./project/scripts/dev/run-tests.sh --cov
```

---

## Infrastructure Changes

### CloudFormation Updates

1. Validate template:
   ```bash
   ./project/scripts/validate.sh dev
   ```

2. Test in dev environment:
   ```bash
   ./project/scripts/deploy.sh dev
   ```

3. Document changes in PR

### Script Changes

- Make scripts executable: `chmod +x script.sh`
- Use `set -e` for error handling
- Add usage documentation
- Test on clean environment

---

## Documentation

### When to Update Docs

- New features → Update README
- Configuration changes → Update `.env.example`
- Deployment changes → Update DEPLOYMENT_CHECKLIST.md
- Dev workflow changes → Update DEVELOPMENT.md

### Documentation Style

- Clear and concise
- Include code examples
- Use markdown formatting
- Add table of contents for long docs

---

## Getting Help

- **Questions**: Open a GitHub Discussion
- **Bugs**: Create an Issue with reproduction steps
- **Feature Requests**: Create an Issue with use case
- **Security Issues**: Email maintainer directly

---

## Review Checklist

Before submitting PR, ensure:

- [ ] Code follows style guide
- [ ] Tests added/updated and passing
- [ ] Documentation updated
- [ ] No sensitive data committed
- [ ] Commit messages follow convention
- [ ] PR description is complete
- [ ] CI/CD checks pass

---

## Thank You! 🙏

Your contributions make this project better for everyone!
