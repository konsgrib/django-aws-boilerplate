#!/usr/bin/env bash

set -eux
cd $(dirname $0)/..
. ./scripts/includes.sh
setup $@

echo "Building and pushing Docker image to ECR"
echo "Stack name: ${stack_name}"
echo "ECR repository: ${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com/${stack_name}"
echo ""

# Build and push Docker image to ECR
docker_image_build ./src ${stack_name}

echo ""
echo "Docker image built and pushed successfully!"
echo "Image: ${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com/${stack_name}:latest"
