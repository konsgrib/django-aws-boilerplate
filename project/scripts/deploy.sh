#!/usr/bin/env bash

set -eux
cd $(dirname $0)/..
. ./scripts/includes.sh
setup $@

echo "Deploying CloudFormation stack: ${stack_name}"
echo "Environment: ${env}"
echo "S3 Bucket: ${s3_bucket}"
echo ""

# Deploy CloudFormation stack
aws cloudformation deploy \
    --stack-name ${stack_name} \
    --template-file ${template_path} \
    --no-fail-on-empty-changeset \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides \
        CompanyName=${company_name} \
        Environment=${env} \
        KeyName=${key_name} \
        AllowedSSHLocation=${allowed_ssh_location} \
        AdminEmailDomain=${ADMIN_EMAIL_DOMAIN} \
        DjangoProjectName=${django_project} \
    --tags \
        project="${project_name}" \
        component="${stack_name}" \
        environment="${env}" \
        company="${company_name}"
