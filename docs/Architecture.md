# Architecture

## Overview

This project deploys a containerised FastAPI application on AWS using Terraform, with a CI/CD pipeline via GitHub Actions. The dev environment is fully provisioned in `ap-south-1`.

## Live Endpoints (dev)

| Endpoint | URL |
|----------|-----|
| Swagger UI | http://devops-app-dev-alb-64195356.ap-south-1.elb.amazonaws.com/docs |
| Health | http://devops-app-dev-alb-64195356.ap-south-1.elb.amazonaws.com/health |
| API Status | http://devops-app-dev-alb-64195356.ap-south-1.elb.amazonaws.com/api/v1/status |
| Metrics | http://devops-app-dev-alb-64195356.ap-south-1.elb.amazonaws.com/metrics |

## AWS Architecture

```
Internet
   │
   ▼ port 80
[ALB: devops-app-dev-alb] ── Public Subnets (ap-south-1a, ap-south-1b)
   │
   ▼ port 8000
[EC2: t3.micro] ── Private App Subnet
   │ Docker via SSM
   ▼
[RDS: devops-app-dev-postgres] ── Private DB Subnets (no internet route)
PostgreSQL 16.4, db.t4g.micro
```

### Networking

- **VPC** — `devops-app-dev` in `ap-south-1`
- **Public subnets** — one per AZ, hosts ALB and Internet Gateway
- **Private app subnets** — EC2 instance, outbound via NAT Gateway
- **Private DB subnets** — RDS, no route to internet or NAT
- **VPC Flow Logs** — all traffic logged to CloudWatch

### Security Groups

| Group | Inbound | Outbound |
|-------|---------|----------|
| ALB (`devops-app-dev-alb-sg`) | TCP 80 from `0.0.0.0/0` | all |
| App EC2 | app port (8000) from ALB SG | 443 to internet, 5432 to RDS SG |
| RDS | 5432 from App SG | none |
| Bastion | 22 from admin CIDRs | all |

### Infrastructure Resources

| Resource | Identifier |
|----------|-----------|
| ECR repository | `829182232239.dkr.ecr.ap-south-1.amazonaws.com/devops-app-dev` |
| RDS instance | `devops-app-dev-postgres` |
| EC2 instance | private subnet, accessed via SSM Session Manager |
| ALB | `devops-app-dev-alb-64195356.ap-south-1.elb.amazonaws.com` |
| Terraform state bucket | `devops-app-tfstate-ap-south-1` |
| State lock table | `devops-app-tfstate-lock` (DynamoDB) |

### State Management

The dev environment uses a single Terraform root (`terraform/environments/dev/`) that provisions all modules in one `terraform apply`. State is stored in S3:

```
s3://devops-app-tfstate-ap-south-1/
  dev/terraform.tfstate
```

DynamoDB table `devops-app-tfstate-lock` provides concurrent-access locking.

### Terraform Module Structure

```
terraform/
  environments/
    dev/
      main.tf       <- calls all modules
      variables.tf
      outputs.tf
      backend.tf
  modules/
    networking/     <- VPC, subnets, IGW, NAT, route tables
    security/       <- security groups
    iam/            <- EC2 instance profile, GitHub Actions role
    rds/            <- data source for manually-created RDS
    ecr/            <- ECR repository + lifecycle rules
    ec2/            <- EC2 instance + user_data
    alb/            <- ALB, target group, listener
    cloudwatch/     <- alarms, log groups, dashboard
```

### Module Dependency Order (within single apply)

```
networking --> security --> iam
                 |
                 v
                rds --> ec2 --> alb --> cloudwatch
                 |
                 v
                ecr
```

## Application

FastAPI (Python 3.12) running in a Docker container on EC2. The container is started via SSM after initial provisioning.

| Endpoint | Purpose |
|----------|---------|
| `/health` | Liveness probe — returns `{"status":"healthy"}` |
| `/ready` | Readiness probe — validates DB connection |
| `/api/v1/status` | Environment info + DB latency |
| `/metrics` | Prometheus metrics |
| `/docs` | Swagger UI |

The container image is tagged `sha-<commit>` and also `latest`, stored in ECR. At runtime the EC2 instance pulls from ECR using its IAM instance profile.

## Environment Settings (dev)

| Setting | Value |
|---------|-------|
| Region | ap-south-1 |
| RDS instance | db.t4g.micro (free tier) |
| Multi-AZ RDS | false |
| EC2 instance | t3.micro |
| ECR tag mutability | MUTABLE |
| Deletion protection | false |
| Backup retention | 0 days (free tier) |
| Storage encryption | false (free tier) |
| NAT Gateway | single |
| OIDC provider | pre-existing (enable_github_oidc = false) |
