setup() {
    set_vars $@
}

set_vars() {
    # ENV parameter defaults to 'dev' if not provided
    env=${1:-dev}
    
    # ========================================
    # GLOBAL COMPANY CONFIGURATION
    # Set these variables to customize deployment for different companies
    # ========================================
    COMPANY_NAME=${COMPANY_NAME:-mycompany}              # Company/client identifier (lowercase, no spaces)
    PROJECT_NAME=${PROJECT_NAME:-web}                    # Project name (for tagging)
    APP_NAME=${APP_NAME:-${COMPANY_NAME}}                # Application name (used in paths, containers)
    DJANGO_PROJECT_NAME=${DJANGO_PROJECT_NAME:-myapp}    # Django project folder name (from src/)
    ADMIN_EMAIL_DOMAIN=${ADMIN_EMAIL_DOMAIN:-${COMPANY_NAME}.com}  # Domain for admin email
    
    # Derived variables (computed from COMPANY_NAME)
    root_dir=$(pwd)
    company_name=${COMPANY_NAME}
    project_name=${PROJECT_NAME}
    app_name=${APP_NAME}
    django_project=${DJANGO_PROJECT_NAME}
    stack_name=${company_name}-${env}
    component_path=${stack_name}
    template_path=./cloudformation/infrastructure/resources.yaml
    s3_bucket=${company_name}-${env}-media
    s3_config_prefix=config
    app_dir=/home/ec2-user/${app_name}                   # EC2 application directory
    secrets_prefix=${company_name}                        # AWS Secrets Manager prefix
    ssm_prefix=/${company_name}                          # SSM Parameter Store prefix
    
    # AWS Configuration
    aws_account_id=$(aws sts get-caller-identity --output text --query Account)
    aws_region=eu-west-1
    key_name=${company_name}                             # EC2 key pair name (must exist in AWS)
    # Set your allowed SSH location (CIDR). You can export ALLOWED_SSH_LOCATION=YOUR_IP/32 to override
    allowed_ssh_location=${ALLOWED_SSH_LOCATION:-0.0.0.0/0}

}



usage() {
    echo "Usage: $0 <ENV>"
    echo "ENV id an environment short name [dev|stag|prod]"
    exit 1
}

sync_configs_to_s3() {
    echo "Syncing configs to S3..."
    aws s3 sync ./config/nginx s3://${s3_bucket}/${s3_config_prefix}/nginx/ --delete
    aws s3 sync ./config/postgres s3://${s3_bucket}/${s3_config_prefix}/postgres/ --delete
    echo "Configs synced to s3://${s3_bucket}/${s3_config_prefix}/"
}

sync_configs_from_s3() {
    target_dir=${1:-/tmp/${app_name}-config}
    echo "Pulling configs from S3 to ${target_dir}..."
    mkdir -p ${target_dir}/{nginx,postgres}
    aws s3 sync s3://${s3_bucket}/${s3_config_prefix}/nginx/ ${target_dir}/nginx/
    aws s3 sync s3://${s3_bucket}/${s3_config_prefix}/postgres/ ${target_dir}/postgres/
    echo "Configs pulled from S3"
}


docker_image_build() {
    source_dir=$1
    ecr_repo_name=$2

    if aws ecr describe-repositories --repository-name ${ecr_repo_name} >/dev/null 2>&1; then
        echo "ECR repo ${ecr_repo_name} already exists. Skipping its creation".
    else
        aws ecr create-repository --repository-name ${ecr_repo_name} >/dev/null
    fi
    cd $source_dir
    aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com
    docker image build --network host -t ${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com/${ecr_repo_name}:latest .
    docker image push ${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com/${ecr_repo_name}:latest
    cd -
}
