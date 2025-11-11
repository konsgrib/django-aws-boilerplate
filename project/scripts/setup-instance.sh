#!/usr/bin/env bash

set -e

cd $(dirname $0)/..
. ./scripts/includes.sh
setup $@

echo "========================================="
echo "Setup ${COMPANY_NAME} on EC2 Instance"
echo "========================================="
echo "Company: ${COMPANY_NAME}"
echo "Environment: ${env}"
echo "Stack: ${stack_name}"
echo ""

# Get EC2 public IP from CloudFormation stack outputs
echo "Fetching EC2 instance public IP..."
EC2_IP=$(aws cloudformation describe-stacks \
    --stack-name ${stack_name} \
    --query "Stacks[0].Outputs[?OutputKey=='PublicIP'].OutputValue" \
    --output text)

if [ -z "$EC2_IP" ]; then
    echo "Error: Could not get EC2 public IP from stack ${stack_name}"
    echo "Make sure the stack is deployed successfully."
    exit 1
fi

echo "EC2 Instance IP: ${EC2_IP}"
echo ""

# Upload configs to S3
echo "Step 1: Syncing configs to S3..."
sync_configs_to_s3
echo ""

# Upload docker-compose.yml to S3
echo "Step 2: Uploading docker-compose.yml to S3..."
aws s3 cp ./docker-compose.yml s3://${s3_bucket}/${s3_config_prefix}/docker-compose.yml
echo ""

# Wait for SSH to be ready
echo "Step 3: Waiting for SSH to be ready..."
PEM_FILE="${root_dir}/../${key_name}.pem"
for i in {1..30}; do
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i "${PEM_FILE}" ec2-user@${EC2_IP} "echo 'SSH ready'" 2>/dev/null; then
        echo "SSH connection established!"
        break
    fi
    echo "Waiting for SSH (attempt $i/30)..."
    sleep 10
done
echo ""

# Execute setup on EC2
echo "Step 4: Setting up application on EC2..."
ssh -o StrictHostKeyChecking=no -i "${PEM_FILE}" ec2-user@${EC2_IP} bash -s <<EOF
set -e

echo "=== EC2 Setup Started ==="

# Create app directory
mkdir -p ${app_dir}
cd ${app_dir}

# Download configs from S3
echo "Downloading configs from S3..."
aws s3 sync s3://${s3_bucket}/${s3_config_prefix}/nginx/ ./config/nginx/
aws s3 sync s3://${s3_bucket}/${s3_config_prefix}/postgres/ ./config/postgres/
aws s3 cp s3://${s3_bucket}/${s3_config_prefix}/docker-compose.yml ./docker-compose.yml
chmod +x ./config/postgres/*.sh 2>/dev/null || true

# Load environment variables from bootstrap
if [ -f /opt/${app_name}/.env ]; then
    echo "Loading environment from /opt/${app_name}/.env"
    cp /opt/${app_name}/.env ./.env
    
    # Add AWS-specific vars for docker-compose
    echo "AWS_ACCOUNT_ID=${aws_account_id}" >> ./.env
    echo "AWS_REGION=${aws_region}" >> ./.env
    echo "STACK_NAME=${stack_name}" >> ./.env
else
    echo "Warning: /opt/${app_name}/.env not found!"
    echo "Make sure UserData completed successfully."
    exit 1
fi

# Login to ECR
echo "Logging into ECR..."
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com

# Pull latest image
echo "Pulling Docker image from ECR..."
docker pull ${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com/${stack_name}:latest

# Stop existing containers
echo "Stopping existing containers..."
docker compose down || true

# Start services
echo "Starting services with docker compose..."
docker compose up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 15

# Check service status
echo "Checking service status..."
docker compose ps

# Test health endpoint
echo "Testing health endpoint..."
sleep 5
curl -f http://localhost/health || echo "Warning: Health check failed"

echo ""
echo "=== EC2 Setup Completed Successfully ==="
echo ""
echo "Application is running at: http://${EC2_IP}"
echo ""
echo "Useful commands:"
echo "  ssh -i ${key_name}.pem ec2-user@${EC2_IP}"
echo "  docker compose logs -f"
echo "  docker compose ps"
echo "  docker compose restart django"
echo ""
EOF

echo ""
echo "========================================="
echo "Setup completed successfully!"
echo "========================================="
echo ""
echo "Application URL: http://${EC2_IP}"
echo ""
echo "To check logs:"
echo "  ssh -i ${PEM_FILE} ec2-user@${EC2_IP}"
echo "  cd ${app_dir}"
echo "  docker compose logs -f"
echo ""
