# Company Configuration Example
#
# To deploy for a different company, export these variables before running deployment scripts:
#
# Example for "newcompany":
# 
# export COMPANY_NAME=newcompany
# export PROJECT_NAME=web
# export APP_NAME=newcompany
# export DJANGO_PROJECT_NAME=myapp          # Django project folder name in src/
# export ADMIN_EMAIL_DOMAIN=newcompany.com
# export AWS_PROFILE=newcompany                    # AWS CLI profile
#
# Then run:
# ./scripts/deploy.sh dev
# ./scripts/build-image.sh dev
# ./scripts/setup-instance.sh dev

# Default configuration (boilerplate example)
export COMPANY_NAME=mycompany
export PROJECT_NAME=web
export APP_NAME=mycompany
export DJANGO_PROJECT_NAME=myapp
export ADMIN_EMAIL_DOMAIN=example.com
export AWS_PROFILE=mycompany

# ========================================
# Configuration Variables Explanation
# ========================================
#
# COMPANY_NAME
#   - Company/client identifier (lowercase, no spaces, no special characters)
#   - Used as prefix for all AWS resources (S3 buckets, Secrets Manager, SSM parameters)
#   - Used in EC2 key pair name
#   - Example: mycompany, acmecorp, client123
#
# PROJECT_NAME
#   - Project name for tagging resources
#   - Example: web, api, platform
#
# APP_NAME
#   - Application name used in EC2 paths and docker container names
#   - Usually same as COMPANY_NAME
#   - Example: myapp, myproject
#
# DJANGO_PROJECT_NAME
#   - Django project folder name from src/ directory
#   - Must match the actual Django project folder
#   - Used in gunicorn command and manage.py
#   - Example: myapp, myproject
#
# ADMIN_EMAIL_DOMAIN
#   - Domain for Django admin superuser email
#   - Used in AWS Secrets Manager for superuser creation
#   - Example: example.com, company.com
#
# AWS_PROFILE
#   - AWS CLI profile name with credentials
#   - Must be configured in ~/.aws/credentials
#   - Example: mycompany, default, production
#
# ========================================
# AWS Resources Created (with COMPANY_NAME prefix)
# ========================================
#
# CloudFormation Stack: ${COMPANY_NAME}-${ENV}
# S3 Bucket: ${COMPANY_NAME}-${ENV}-media
# EC2 Instance: ${COMPANY_NAME}-${ENV}-ec2-instance
# IAM Role: ${COMPANY_NAME}-${ENV}-ec2-role
# Security Group: ${COMPANY_NAME}-${ENV}-security-group
# ECR Repository: ${COMPANY_NAME}-${ENV}
# Secrets Manager:
#   - ${COMPANY_NAME}/${ENV}/django/SECRET_KEY
#   - ${COMPANY_NAME}/${ENV}/database/credentials
#   - ${COMPANY_NAME}/${ENV}/django/superuser
# SSM Parameters:
#   - /${COMPANY_NAME}/${ENV}/app/*
#   - /${COMPANY_NAME}/${ENV}/ssh/*
#
# ========================================
# Multi-Tenant Deployment Example
# ========================================
#
# Deploy for Company A:
#   export COMPANY_NAME=companya
#   export ADMIN_EMAIL_DOMAIN=companya.com
#   export AWS_PROFILE=companya
#   ./scripts/deploy.sh dev
#
# Deploy for Company B:
#   export COMPANY_NAME=companyb
#   export ADMIN_EMAIL_DOMAIN=companyb.com
#   export AWS_PROFILE=companyb
#   ./scripts/deploy.sh dev
#
# Both deployments will have completely isolated resources in AWS!
