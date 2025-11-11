We are building a system that will be running on AWS EC2 t3.micro instance having Amazon linux 2023 on board in the eu-west-1 region.
This instance will be hosting 3 docker containers 
    Nginx
    Django gthis will be the container we are storing in ECR
    Postgres
Configuration and media files will be stored in s3 bucker specific locations
    Nginx files /nginx/config
                /nginx/static
                /nginx/cert
    Postgres files /postgres/data

Django config and db credentials will be stored in parameter store or secret, whet is better to be decieded

Local Development
locally configs are stored on /project/config/nginx, /project/config/postgres folders
cloudformation template is stored in /project/cloudformation/infrastructure/resources.yaml

folder /project/scripts contains next files:
    includes.sh contains all the variables definitions and procedures definitions
        set_vars - define all project variables
        docker_image_build - build and push Docker image to ECR
        sync_configs_to_s3 - upload nginx/postgres configs to S3
        sync_configs_from_s3 - download configs from S3 (runs on EC2)

    deploy.sh calling procedures from includes for CloudFormation stack deployment
    validate.sh validates the CloudFormation template
    delete.sh deletes stack by using procedures from the includes
    lint.sh perform linting by using black
    setup-instance.sh runs locally via SSH to EC2 for application deployment
        - pulls configs from S3
        - starts docker-compose
        - runs Django migrations
        - verifies health check

Cost Optimization
    - Use t3.micro (free tier eligible)
    - S3 lifecycle policies for old media files (move to Glacier after 90 days)
    - CloudWatch logs with retention policy (7 days)
    - No NAT Gateway, no Load Balancer
    - Stop instance automatically during non-working hours (optional)

Monitoring & Backup
    - CloudWatch metrics for basic monitoring (CPU, disk, memory)
    - S3 versioning enabled for disaster recovery
    - Daily automated snapshots via CloudWatch Events (keep last 7)
    - Postgres backup to S3 via cron job

Security
    - SSH key in Parameter Store (encrypted)
    - Django SECRET_KEY in Secrets Manager
    - DB credentials in Secrets Manager
    - Security Group restricts SSH to specific IP (update from 0.0.0.0/0)
    - HTTPS only (port 443) with Let's Encrypt SSL cert

Docker Compose
    - docker-compose.yml defines all 3 containers
    - Environment variables loaded from .env file
    - .env file populated from AWS Parameter Store on deployment
    - Volume mounts for postgres data and nginx configs

Deployment Process
    Infrastructure (first time):
        1. validate.sh - validate CloudFormation template
        2. sync_configs_to_s3 - upload nginx/postgres configs to S3
        3. deploy.sh - deploy CloudFormation stack (creates EC2, S3, IAM, Security Groups)
        4. Wait for EC2 UserData to complete (Docker, git installation)
    
    Application deployment (after infrastructure ready):
        1. build Docker image and push to ECR
        2. setup-instance.sh - SSH to EC2 and:
            - pull configs from S3
            - pull Docker image from ECR
            - start docker-compose
            - run Django migrations
            - verify health check endpoint
    
    Updates (code changes):
        1. Build and push new Docker image to ECR
        2. SSH to EC2: docker-compose pull && docker-compose up -d
