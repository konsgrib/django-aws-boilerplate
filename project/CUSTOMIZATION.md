# Customization Guide

This boilerplate comes with default names that should be customized for your project.

## Quick Rename Checklist

### 1. Django Project Name

The Django project folder is currently named `myapp` in `project/src/myapp/`.

**To rename:**

```bash
cd project/src
mv myapp myproject  # Replace 'myproject' with your desired name
```

**Then update these files:**

- `src/manage.py` - line 9: `'myapp.settings'` → `'myproject.settings'`
- `src/myproject/settings.py` - line 53, 70
- `src/myproject/asgi.py` - line 14
- `src/myproject/wsgi.py` - line 14
- `src/create_superuser.py` - line 8
- `src/pytest.ini` - line 2
- `src/Dockerfile` - line 47 (gunicorn command)

**Find all occurrences:**
```bash
grep -r "myapp" project/src/ --exclude-dir=__pycache__
```

### 2. Company/Project Identifiers

Update default values in configuration files:

#### `project/scripts/includes.sh`
```bash
COMPANY_NAME=${COMPANY_NAME:-mycompany}
DJANGO_PROJECT_NAME=${DJANGO_PROJECT_NAME:-myproject}
```

#### `project/cloudformation/infrastructure/resources.yaml`
Lines 20, 35, 43, 47 - change default values from `mycompany` to your company name.

#### Docker Compose Files

**`project/docker-compose.local.yml`:**
- Database name, username (lines 12-13)
- Container names (lines 10, 31, 73)
- Network name (line 98)

**`project/docker-compose.yml`:**
- Same as above for production compose file

#### Environment Files

**`project/.env.example` and `project/src/.env.example`:**
- `DB_NAME`, `DB_USERNAME`
- `DJANGO_SUPERUSER_EMAIL` domain
- `S3_BUCKET`, `STACK_NAME`

### 3. Configuration Files

#### `project/company-config.example.sh`
Update all example values (lines 20-25).

#### `project/config/nginx/autoakademia.conf`
Rename file to match your project name.

### 4. Documentation

Update references in:
- `project/README.md`
- `project/DEVELOPMENT.md`
- `project/CONTRIBUTING.md`
- `project/DJANGO_ADMIN.md`
- `project/MULTI_TENANT.md`

### 5. AWS Resources

When deploying, AWS resources will use names like:
- Stack: `{COMPANY_NAME}-{env}` (e.g., `mycompany-dev`)
- S3 bucket: `{COMPANY_NAME}-{env}-media`
- Secrets: `{COMPANY_NAME}/{env}/*`
- EC2 key pair: `{COMPANY_NAME}` (must be created manually)

## Automated Rename Script

Create `rename-project.sh`:

```bash
#!/bin/bash

OLD_NAME="myapp"
NEW_NAME="$1"

if [ -z "$NEW_NAME" ]; then
  echo "Usage: ./rename-project.sh <new-project-name>"
  exit 1
fi

echo "Renaming Django project from $OLD_NAME to $NEW_NAME..."

# Rename Django project directory
mv "project/src/$OLD_NAME" "project/src/$NEW_NAME"

# Update all Python files
find project/src -type f -name "*.py" -exec sed -i "s/$OLD_NAME/$NEW_NAME/g" {} +

# Update configuration files
sed -i "s/$OLD_NAME/$NEW_NAME/g" project/src/pytest.ini
sed -i "s/$OLD_NAME/$NEW_NAME/g" project/src/Dockerfile
sed -i "s/$OLD_NAME/$NEW_NAME/g" project/scripts/includes.sh
sed -i "s/$OLD_NAME/$NEW_NAME/g" project/cloudformation/infrastructure/resources.yaml
sed -i "s/$OLD_NAME/$NEW_NAME/g" project/docker-compose*.yml
sed -i "s/$OLD_NAME/$NEW_NAME/g" project/.env.example
sed -i "s/$OLD_NAME/$NEW_NAME/g" project/src/.env.example
sed -i "s/$OLD_NAME/$NEW_NAME/g" project/company-config.example.sh

# Rename nginx config
mv "project/config/nginx/$OLD_NAME.conf" "project/config/nginx/$NEW_NAME.conf"

echo "✅ Project renamed to $NEW_NAME"
echo ""
echo "⚠️  Manual steps required:"
echo "1. Review changes: git diff"
echo "2. Update documentation files (README.md, DEVELOPMENT.md, etc.)"
echo "3. Update GitHub repository name/description"
echo "4. Create AWS resources with new name"
```

Make it executable:
```bash
chmod +x rename-project.sh
```

## Usage Examples

### For Local Development

Set environment variables before running:

```bash
export COMPANY_NAME=mycompany
export DJANGO_PROJECT_NAME=myproject
export ADMIN_EMAIL_DOMAIN=mycompany.com
./project/scripts/dev/local-dev.sh
```

### For AWS Deployment

Use `company-config.sh`:

```bash
cp project/company-config.example.sh company-config-mycompany.sh
# Edit company-config-mycompany.sh with your values
source company-config-mycompany.sh
cd project && ./scripts/deploy.sh dev
```

## Testing After Rename

1. **Test local development:**
   ```bash
   cd project
   ./scripts/dev/local-dev.sh
   ```

2. **Run tests:**
   ```bash
   ./scripts/dev/run-tests.sh
   ```

3. **Verify imports:**
   ```bash
   cd project/src
   python manage.py check
   ```

4. **Test Docker build:**
   ```bash
   docker build -t test-build ./project/src/
   ```

## Common Issues

### Import Errors After Rename

If you see `ModuleNotFoundError: No module named 'myapp'`:
- Check all Python files for old import statements
- Restart Django development server
- Clear `__pycache__` directories: `find . -type d -name __pycache__ -exec rm -rf {} +`

### Database Connection Issues

If database connection fails:
- Check `DB_NAME` and `DB_USERNAME` in `.env` match docker-compose.yml
- Ensure `settings.py` database configuration uses correct project name

### Nginx Configuration

If nginx can't start:
- Verify nginx config file is renamed
- Check docker-compose.yml references correct config file path

## Support

For issues or questions, open an issue on GitHub.
