# Deployment Guide

## Prerequisites

- AWS CLI configured with sufficient permissions to create the S3 state bucket and DynamoDB lock table
- Terraform >= 1.6.0
- Docker
- GitHub repository with the following Secrets set

### Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `DEV_DEPLOY_ROLE_ARN` | IAM role ARN for dev deployments (OIDC) |
| `QA_DEPLOY_ROLE_ARN` | IAM role ARN for qa deployments (OIDC) |
| `PROD_DEPLOY_ROLE_ARN` | IAM role ARN for prod deployments (OIDC) |

### Required GitHub Environments

Create a `production` environment in GitHub with required reviewers. The `deploy-prod.yml` workflow gates the apply and deploy jobs on this environment.

## First-Time Bootstrap

### 1. Create state backend resources

```bash
aws s3 mb s3://devops-app-tfstate-ap-south-1 --region ap-south-1
aws s3api put-bucket-versioning \
  --bucket devops-app-tfstate-ap-south-1 \
  --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption \
  --bucket devops-app-tfstate-ap-south-1 \
  --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

aws dynamodb create-table \
  --table-name devops-app-tfstate-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-south-1
```

### 2. Deploy each layer for an environment

Replace `dev` with `qa` or `prod` as needed.

```bash
for layer in networking security iam rds ecr ec2 cloudwatch; do
  cd terraform/environments/dev/$layer
  terraform init
  terraform apply
  cd -
done
```

### 3. Build and push the initial Docker image

```bash
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com"
REPO="devops-app-dev"

aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin "$ECR_REGISTRY"

docker build -t "$ECR_REGISTRY/$REPO:latest" application/
docker push "$ECR_REGISTRY/$REPO:latest"
```

## CI/CD Pipeline

### Branch → Environment mapping

| Branch pattern | Workflow | Environment |
|----------------|----------|-------------|
| `feature/**`, `develop` | `deploy-dev.yml` | dev |
| `develop` | `deploy-qa.yml` | qa |
| `main` | `deploy-prod.yml` | prod (with manual approval) |

### Workflow stages

1. **CI** (`ci.yml`) — runs on every push; terraform fmt check, module validate, Docker build, Trivy scan
2. **Build & Push** — builds Docker image, tags with `sha-<commit>`, pushes to ECR
3. **Terraform Apply** — applies all seven layers in dependency order
4. **Deploy App** — SSM Run Command to pull new image and restart the systemd service

## Local Development

```bash
cd application
cp .env.example .env   # fill in DATABASE_* values
docker compose up
```

Access:
- App: http://localhost:8000
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (admin / value from .env `GRAFANA_ADMIN_PASSWORD`)
