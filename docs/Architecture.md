# Architecture

## Overview

This project deploys a containerised FastAPI application on AWS across three isolated environments (dev, qa, prod) using Terraform.

## AWS Architecture

```
Internet
   │
   ▼
[Internet Gateway]
   │
   ▼
[ALB / Bastion] ── Public Subnets (x AZs)
   │
   ▼
[EC2 App Instance] ── Private App Subnets (x AZs)
   │
   ▼
[RDS PostgreSQL] ── Private DB Subnets (x AZs, no route table)
```

### Networking

- **VPC** — isolated per environment (`/20` CIDR)
- **Public subnets** — one per AZ, hosts bastion and future load balancer
- **Private app subnets** — one per AZ, EC2 app instances; outbound via NAT Gateway
- **Private DB subnets** — one per AZ, RDS; no internet route
- **VPC Flow Logs** — all traffic logged to CloudWatch

### Security Groups

| Group | Inbound | Outbound |
|-------|---------|----------|
| ALB | 80, 443 from `0.0.0.0/0` | app port to App SG |
| App | app port from ALB SG | 443 to internet, 5432 to RDS SG |
| RDS | 5432 from App SG | none |
| Bastion | 22 from admin CIDRs | all |

### State Management

Each environment × module combination is an independent Terraform root with its own state key:

```
s3://devops-app-tfstate-ap-south-1/
  dev/networking/terraform.tfstate
  dev/security/terraform.tfstate
  dev/iam/terraform.tfstate
  dev/rds/terraform.tfstate
  dev/ecr/terraform.tfstate
  dev/ec2/terraform.tfstate
  dev/cloudwatch/terraform.tfstate
  qa/...
  prod/...
```

Cross-layer dependencies are resolved via `terraform_remote_state` data sources.

### Deployment Order

```
networking → security → iam → rds → ecr → ec2 → cloudwatch
```

Each layer reads outputs from the layers above it.

## Application

FastAPI (Python 3.12) running in a Docker container on EC2.

- **/health** — liveness probe
- **/ready** — readiness probe (validates DB connection)
- **/api/v1/status** — environment status including DB latency
- **/metrics** — Prometheus metrics

The container runs as a non-root user (`appuser`) inside an Alpine image.

## Environment Differences

| Setting | dev | qa | prod |
|---------|-----|----|------|
| RDS instance | db.t3.micro | db.t3.small | db.t3.medium |
| Multi-AZ RDS | false | false | true |
| EC2 instance | t3.micro | t3.small | t3.medium |
| ECR tag mutability | MUTABLE | MUTABLE | IMMUTABLE |
| Deletion protection | false | false | true |
| Log retention | 30 days | 30 days | 90 days |
| NAT Gateway | single | single | single |
