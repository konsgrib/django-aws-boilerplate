#!/usr/bin/env bash

set -eux
cd $(dirname $0)/..
. ./scripts/includes.sh
setup $@

echo "Deleting stack: ${stack_name} for environment: ${env}"
echo "S3 bucket: ${s3_bucket}"
echo ""
read -p "Are you sure you want to delete this stack? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

# Optionally empty S3 bucket before stack deletion (uncomment if needed)
# aws s3 rm s3://${s3_bucket} --recursive

aws cloudformation delete-stack \
    --stack-name ${stack_name}

echo "Waiting for stack deletion to complete..."
aws cloudformation wait stack-delete-complete \
    --stack-name ${stack_name}

echo "Stack ${stack_name} deleted successfully."
