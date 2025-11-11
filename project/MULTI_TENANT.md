# Multi-Tenant Deployment Guide

## Overview

This project supports deploying the same application for multiple companies/clients with complete resource isolation. Each company gets its own:
- CloudFormation stack
- S3 buckets
- Secrets Manager secrets
- EC2 instances
- ECR repositories
- SSM parameters

## Configuration Variables

All company-specific settings are controlled via environment variables in `scripts/includes.sh`:

### Primary Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `COMPANY_NAME` | Company identifier (lowercase, alphanumeric + hyphens) | `mycompany`, `clientcorp` |
| `PROJECT_NAME` | Project name for tagging | `web`, `api` |
| `APP_NAME` | Application directory name on EC2 | Same as `COMPANY_NAME` |
| `DJANGO_PROJECT_NAME` | Django project folder from `src/` | `mycompany` |
| `ADMIN_EMAIL_DOMAIN` | Domain for admin@domain.com | `example.com` |
| `AWS_PROFILE` | AWS CLI profile with credentials | `mycompany`, `default` |

### Derived Variables (Auto-computed)

These are automatically calculated from `COMPANY_NAME`:

- `stack_name`: `${COMPANY_NAME}-${ENV}` 
- `s3_bucket`: `${COMPANY_NAME}-${ENV}-media`
- `key_name`: `${COMPANY_NAME}` (EC2 key pair)
- `app_dir`: `/home/ec2-user/${APP_NAME}`
- `secrets_prefix`: `${COMPANY_NAME}`
- `ssm_prefix`: `/${COMPANY_NAME}`

## AWS Resources Naming

All AWS resources are prefixed with company name for isolation:

```
CloudFormation Stack:  {COMPANY_NAME}-{ENV}
S3 Bucket:            {COMPANY_NAME}-{ENV}-media
ECR Repository:       {COMPANY_NAME}-{ENV}
IAM Role:             {COMPANY_NAME}-{ENV}-ec2-role
Security Group:       {COMPANY_NAME}-{ENV}-security-group
EC2 Instance:         {COMPANY_NAME}-{ENV}-ec2-instance

Secrets Manager:
  {COMPANY_NAME}/{ENV}/django/SECRET_KEY
  {COMPANY_NAME}/{ENV}/database/credentials
  {COMPANY_NAME}/{ENV}/django/superuser

SSM Parameters:
  /{COMPANY_NAME}/{ENV}/app/ALLOWED_HOSTS
  /{COMPANY_NAME}/{ENV}/app/DEBUG
  /{COMPANY_NAME}/{ENV}/app/S3_BUCKET
  /{COMPANY_NAME}/{ENV}/ssh/authorized_key
```

## Deployment for New Company

### Step 1: Set Environment Variables

Create a configuration file (e.g., `company-newclient.env`):

```bash
#!/bin/bash
export COMPANY_NAME=newclient
export PROJECT_NAME=web
export APP_NAME=newclient
export DJANGO_PROJECT_NAME=autoakademia  # Keep if Django project unchanged
export ADMIN_EMAIL_DOMAIN=newclient.com
export AWS_PROFILE=newclient
```

Load it:
```bash
source company-newclient.env
```

### Step 2: Create EC2 Key Pair

```bash
aws ec2 create-key-pair \
  --key-name newclient \
  --query 'KeyMaterial' \
  --output text > ../newclient.pem

chmod 600 ../newclient.pem
```

### Step 3: Deploy Infrastructure

```bash
./scripts/deploy.sh dev
```

This creates:
- CloudFormation stack: `newclient-dev`
- S3 bucket: `newclient-dev-media`
- Secrets with random passwords
- EC2 instance with IAM role

### Step 4: Build & Push Docker Image

```bash
./scripts/build-image.sh dev
```

Creates ECR repository `newclient-dev` and pushes image.

### Step 5: Setup Application on EC2

```bash
./scripts/setup-instance.sh dev
```

Downloads configs, starts containers, runs migrations, creates superuser.

### Step 6: Get Admin Credentials

```bash
aws secretsmanager get-secret-value \
  --secret-id newclient/dev/django/superuser \
  --query SecretString \
  --output text | jq '.'
```

## Managing Multiple Companies

### Example: Deploy for 3 companies

```bash
# Company A
export COMPANY_NAME=companya
export ADMIN_EMAIL_DOMAIN=companya.com
export AWS_PROFILE=companya
./scripts/deploy.sh dev
./scripts/build-image.sh dev
./scripts/setup-instance.sh dev

# Company B
export COMPANY_NAME=companyb
export ADMIN_EMAIL_DOMAIN=companyb.com
export AWS_PROFILE=companyb
./scripts/deploy.sh dev
./scripts/build-image.sh dev
./scripts/setup-instance.sh dev

# Company C
export COMPANY_NAME=companyc
export ADMIN_EMAIL_DOMAIN=companyc.com
export AWS_PROFILE=companyc
./scripts/deploy.sh dev
./scripts/build-image.sh dev
./scripts/setup-instance.sh dev
```

Each company has completely isolated resources!

## Environment Overrides

All variables can be overridden before running scripts:

```bash
# Deploy with custom settings
COMPANY_NAME=testclient \
ADMIN_EMAIL_DOMAIN=test.com \
AWS_PROFILE=testing \
  ./scripts/deploy.sh dev
```

## CloudFormation Parameters

The template accepts these parameters (auto-filled by deploy script):

- `CompanyName`: From `COMPANY_NAME` env var
- `Environment`: dev/stag/prod
- `KeyName`: From `COMPANY_NAME` (EC2 key pair)
- `AllowedSSHLocation`: SSH access CIDR
- `AdminEmailDomain`: From `ADMIN_EMAIL_DOMAIN`
- `DjangoProjectName`: From `DJANGO_PROJECT_NAME`

## Switching Between Companies

```bash
# Work with company A
export COMPANY_NAME=companya
export AWS_PROFILE=companya
aws cloudformation describe-stacks --stack-name companya-dev

# Switch to company B
export COMPANY_NAME=companyb
export AWS_PROFILE=companyb
aws cloudformation describe-stacks --stack-name companyb-dev
```

## Cleanup

Delete company resources:

```bash
export COMPANY_NAME=oldclient
export AWS_PROFILE=oldclient
./scripts/delete.sh
```

This removes:
- CloudFormation stack
- S3 bucket (if empty)
- ECR images
- Secrets Manager secrets
- SSM parameters

## Best Practices

1. **One AWS Account per Company**: Use separate AWS accounts for production isolation
2. **AWS Profiles**: Configure `~/.aws/credentials` with profile per company
3. **Key Management**: Store `.pem` files securely outside repository
4. **Secret Rotation**: Rotate passwords periodically using AWS Secrets Manager
5. **Tagging**: All resources tagged with company name for cost allocation
6. **Naming Convention**: Use lowercase, alphanumeric + hyphens only

## Troubleshooting

### "Stack already exists" error
Check if `COMPANY_NAME` conflicts with existing stack:
```bash
aws cloudformation list-stacks --query "StackSummaries[?StackName=='${COMPANY_NAME}-dev'].StackName"
```

### Wrong AWS profile
Verify current profile:
```bash
aws sts get-caller-identity
```

### Key pair not found
List available keys:
```bash
aws ec2 describe-key-pairs --query "KeyPairs[].KeyName"
```

Create missing key:
```bash
aws ec2 create-key-pair --key-name ${COMPANY_NAME}
```
