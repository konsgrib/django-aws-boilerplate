# Deployment Checklist

## Initial Setup (One-time)

- [ ] AWS CLI installed and configured
- [ ] Docker installed locally
- [ ] Git clone repository
- [ ] Review `company-config.example.sh` for configuration options

## Deploy New Company

### 1. Configuration (5 min)

- [ ] Set company name: `export COMPANY_NAME=mycompany`
- [ ] Set admin domain: `export ADMIN_EMAIL_DOMAIN=mycompany.com`
- [ ] Set AWS profile: `export AWS_PROFILE=mycompany`
- [ ] Verify AWS credentials: `aws sts get-caller-identity`

### 2. Create EC2 Key (2 min)

```bash
aws ec2 create-key-pair --key-name ${COMPANY_NAME} \
  --query 'KeyMaterial' --output text > ../${COMPANY_NAME}.pem
chmod 600 ../${COMPANY_NAME}.pem
```

- [ ] Key pair created
- [ ] Permissions set to 600

### 3. Deploy Infrastructure (10 min)

```bash
cd project
./scripts/validate.sh        # Optional: validate template
./scripts/deploy.sh dev
```

- [ ] CloudFormation stack created successfully
- [ ] Wait for stack status: `CREATE_COMPLETE`
- [ ] Verify EC2 instance is running

### 4. Build & Push Docker Image (5 min)

```bash
./scripts/build-image.sh dev
```

- [ ] Docker image built
- [ ] ECR repository created
- [ ] Image pushed to ECR

### 5. Setup Application (10 min)

```bash
./scripts/setup-instance.sh dev
```

- [ ] Configs uploaded to S3
- [ ] SSH connection successful
- [ ] Docker containers started:
  - [ ] postgres (healthy)
  - [ ] django (up)
  - [ ] nginx (up)
- [ ] Migrations applied
- [ ] Superuser created
- [ ] Health check passed

### 6. Verify Deployment (5 min)

```bash
# Get EC2 IP
STACK_NAME=${COMPANY_NAME}-dev
EC2_IP=$(aws cloudformation describe-stacks --stack-name ${STACK_NAME} \
  --query "Stacks[0].Outputs[?OutputKey=='PublicIP'].OutputValue" --output text)

# Test health endpoint
curl http://${EC2_IP}/health
# Expected: "healthy"

# Test admin redirect
curl -I http://${EC2_IP}/admin/
# Expected: 302 redirect to /admin/login/
```

- [ ] Health endpoint returns "healthy"
- [ ] Admin page redirects to login
- [ ] Application accessible in browser

### 7. Get Admin Credentials (1 min)

```bash
aws secretsmanager get-secret-value \
  --secret-id ${COMPANY_NAME}/dev/django/superuser \
  --query SecretString --output text | jq '.'
```

- [ ] Username: `admin`
- [ ] Password retrieved
- [ ] Email: `admin@${ADMIN_EMAIL_DOMAIN}`

### 8. Login to Admin Panel

- [ ] Open `http://${EC2_IP}/admin/` in browser
- [ ] Login with username and password
- [ ] Admin dashboard accessible

## Total Time: ~40 minutes

## Update Application

### Code Changes

```bash
./scripts/build-image.sh dev
ssh -i ../${COMPANY_NAME}.pem ec2-user@${EC2_IP}
cd /home/ec2-user/${COMPANY_NAME}
docker compose pull django
docker compose up -d django
```

- [ ] New image built and pushed
- [ ] Django container restarted
- [ ] Application updated

### Config Changes

```bash
# Upload new configs
S3_BUCKET=${COMPANY_NAME}-dev-media
aws s3 sync ./config/nginx s3://${S3_BUCKET}/config/nginx/ --delete
aws s3 sync ./config/postgres s3://${S3_BUCKET}/config/postgres/ --delete

# Download and restart on EC2
ssh -i ../${COMPANY_NAME}.pem ec2-user@${EC2_IP}
cd /home/ec2-user/${COMPANY_NAME}
aws s3 sync s3://${S3_BUCKET}/config/nginx/ ./config/nginx/
docker compose restart nginx
```

- [ ] Configs uploaded to S3
- [ ] Configs downloaded on EC2
- [ ] Services restarted

## Troubleshooting

### Check CloudFormation Status
```bash
aws cloudformation describe-stacks --stack-name ${COMPANY_NAME}-dev \
  --query "Stacks[0].StackStatus"
```

### Check EC2 UserData Logs
```bash
ssh -i ../${COMPANY_NAME}.pem ec2-user@${EC2_IP}
sudo tail -f /var/log/userdata.log
```

### Check Docker Containers
```bash
ssh -i ../${COMPANY_NAME}.pem ec2-user@${EC2_IP}
cd /home/ec2-user/${COMPANY_NAME}
docker compose ps
docker compose logs django --tail 50
docker compose logs nginx --tail 50
docker compose logs postgres --tail 50
```

### Check Environment Variables
```bash
ssh -i ../${COMPANY_NAME}.pem ec2-user@${EC2_IP}
cat /opt/${COMPANY_NAME}/.env
```

### Restart All Services
```bash
ssh -i ../${COMPANY_NAME}.pem ec2-user@${EC2_IP}
cd /home/ec2-user/${COMPANY_NAME}
docker compose restart
```

## Cleanup

```bash
# Set company context
export COMPANY_NAME=oldcompany
export AWS_PROFILE=oldcompany

# Clear S3 bucket
aws s3 rm s3://${COMPANY_NAME}-dev-media --recursive

# Delete stack
./scripts/delete.sh dev

# Delete key pair (optional)
aws ec2 delete-key-pair --key-name ${COMPANY_NAME}
rm ../${COMPANY_NAME}.pem
```

- [ ] S3 bucket emptied
- [ ] CloudFormation stack deleted
- [ ] ECR images removed
- [ ] Key pair deleted
- [ ] PEM file removed

## Multi-Company Deployment

To deploy for multiple companies, repeat the entire process with different `COMPANY_NAME`:

```bash
# Company A
export COMPANY_NAME=companya
export ADMIN_EMAIL_DOMAIN=companya.com
export AWS_PROFILE=companya
# ... run all deployment steps ...

# Company B
export COMPANY_NAME=companyb
export ADMIN_EMAIL_DOMAIN=companyb.com
export AWS_PROFILE=companyb
# ... run all deployment steps ...
```

All resources are completely isolated!

## Production Checklist

Additional steps for production deployment:

- [ ] Change `AllowedSSHLocation` from `0.0.0.0/0` to specific IP/CIDR
- [ ] Set up Route53 domain and SSL certificate
- [ ] Enable CloudWatch logging and monitoring
- [ ] Configure automated backups for PostgreSQL
- [ ] Set up S3 lifecycle policies for media
- [ ] Review and rotate secrets regularly
- [ ] Configure CloudWatch alarms for critical metrics
- [ ] Enable EC2 termination protection
- [ ] Set up automated snapshots
- [ ] Document disaster recovery procedures
