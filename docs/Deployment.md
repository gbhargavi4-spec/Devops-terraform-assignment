# Deployment Guide

## Prerequisites

- AWS CLI configured with sufficient permissions
- Terraform >= 1.6.0
- Docker
- GitHub repository with Actions secrets configured

### Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS access key for CI/CD |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key for CI/CD |

### Required GitHub Environments

The `deploy-dev.yml` workflow triggers on pushes to `feature/**`, `develop`, and `main`.

## First-Time Bootstrap

### 1. Create state backend resources

```bash
aws s3 mb s3://devops-app-tfstate-ap-south-1 --region ap-south-1
aws s3api put-bucket-versioning \
  --bucket devops-app-tfstate-ap-south-1 \
  --versioning-configuration Status=Enabled

aws dynamodb create-table \
  --table-name devops-app-tfstate-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-south-1
```

### 2. Create RDS manually (required — see Challenges)

Terraform cannot determine a valid PostgreSQL engine version via the API. Create the instance via CLI:

```bash
aws rds create-db-instance \
  --db-instance-identifier devops-app-dev-postgres \
  --db-instance-class db.t4g.micro \
  --engine postgres \
  --engine-version 16.4 \
  --master-username devopsadmin \
  --master-user-password "DevOps2024Secure" \
  --db-name devopsdb \
  --allocated-storage 20 \
  --no-multi-az \
  --no-publicly-accessible \
  --storage-type gp2 \
  --backup-retention-period 0 \
  --region ap-south-1
```

Wait for it to become Available:
```bash
aws rds wait db-instance-available --db-instance-identifier devops-app-dev-postgres --region ap-south-1
```

Store the password in SSM:
```bash
aws ssm put-parameter \
  --name "/devops-app/dev/rds/password" \
  --value "DevOps2024Secure" \
  --type SecureString \
  --region ap-south-1
```

### 3. Run Terraform

```bash
cd terraform/environments/dev
terraform init
terraform apply
```

This provisions: VPC, subnets, security groups, IAM roles, ECR, EC2, ALB, and CloudWatch (the RDS module uses a data source to read the manually-created instance).

### 4. Build and push the initial Docker image

```bash
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com"
REPO="devops-app-dev"

aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin "$ECR_REGISTRY"

docker build -t "$ECR_REGISTRY/$REPO:latest" application/
docker push "$ECR_REGISTRY/$REPO:latest"
```

### 5. Start the application via SSM

Get the EC2 instance ID from Terraform output:
```bash
terraform output ec2_instance_id
```

Then send the run command (replace `INSTANCE_ID` and `DB_HOST`):
```bash
DB_HOST=$(aws rds describe-db-instances \
  --db-instance-identifier devops-app-dev-postgres \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text --region ap-south-1)

aws ssm send-command \
  --instance-ids "INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --region ap-south-1 \
  --parameters "commands=[
    'aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 829182232239.dkr.ecr.ap-south-1.amazonaws.com',
    'docker pull 829182232239.dkr.ecr.ap-south-1.amazonaws.com/devops-app-dev:latest',
    'docker stop devops-app 2>/dev/null || true',
    'docker rm devops-app 2>/dev/null || true',
    'docker run -d --name devops-app --restart unless-stopped -p 8000:8000 -e DATABASE_HOST=$DB_HOST -e DATABASE_PORT=5432 -e DATABASE_NAME=devopsdb -e DATABASE_USER=devopsadmin -e DATABASE_PASSWORD=DevOps2024Secure -e ENVIRONMENT=dev 829182232239.dkr.ecr.ap-south-1.amazonaws.com/devops-app-dev:latest'
  ]"
```

## CI/CD Pipeline

### Workflow job order

The `deploy-dev.yml` workflow runs jobs in this order:

```
terraform-apply
      |
      v
build-and-push
      |
      v
deploy-app
```

Terraform runs first so that ECR exists before the Docker build job tries to push to it.

### Job: terraform-apply

- Runs `terraform init` and `terraform apply -auto-approve` in `terraform/environments/dev/`
- Uses `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` secrets

### Job: build-and-push

- Builds the Docker image from `application/`
- Tags: `sha-<git-commit>` and `latest`
- Pushes to ECR `devops-app-dev`

### Job: deploy-app

- Calls SSM Run Command on the EC2 instance to pull the new image and restart the container

## Verifying the Deployment

```bash
# Health check
curl http://devops-app-dev-alb-64195356.ap-south-1.elb.amazonaws.com/health

# Application status
curl http://devops-app-dev-alb-64195356.ap-south-1.elb.amazonaws.com/api/v1/status

# Swagger UI
open http://devops-app-dev-alb-64195356.ap-south-1.elb.amazonaws.com/docs
```

## Local Development

```bash
cd application
cp .env.example .env   # fill in DATABASE_* values
docker compose up
```

Access:
- App: http://localhost:8000/docs
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000
