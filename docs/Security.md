# Security

## Secrets Management

No secrets are hardcoded in Terraform or application source files.

- **Database password** — stored as a `SecureString` in SSM Parameter Store at `/devops-app/dev/rds/password`. The EC2 instance retrieves it at runtime via the IAM instance profile. The password is set once and managed out-of-band (not rotated by Terraform) using `lifecycle { ignore_changes = [value] }`.
- **GitHub Actions** — uses `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` repository secrets. An OIDC-based role (`enable_github_oidc = false`) is defined in the IAM module but not used in dev because the OIDC provider already existed in the account and was not re-created by Terraform.

## IAM — Least Privilege

| Role | Permissions |
|------|-------------|
| EC2 instance profile (`devops-app-dev-ec2-role`) | CloudWatch PutMetricData, SSM GetParameter for `/devops-app/dev/*`, ECR GetAuthorizationToken + pull, SSM Session Manager |
| GitHub Actions deploy | ECR push to `devops-app-dev`, Terraform state access (S3 + DynamoDB), EC2 SSM SendCommand |
| RDS Enhanced Monitoring | AWS managed `AmazonRDSEnhancedMonitoringRole` |

IAM policies use `aws_iam_policy_document` data sources — no inline JSON strings.

**Note:** `rds:DescribeDBInstances` is not currently in the EC2 role. If the application needs to self-discover the DB endpoint, that permission must be added to the instance profile policy.

## Network Security

- **RDS subnets** have no route table — no path to/from the internet or NAT Gateway
- **Security groups** use the AWS Provider 5.x resource model (`aws_vpc_security_group_ingress_rule` / `aws_vpc_security_group_egress_rule`) with no inline rules, enabling independent lifecycle management
- **EC2 IMDSv2** is required (`http_tokens = "required"`) — blocks SSRF-based metadata credential theft
- **VPC Flow Logs** capture all traffic for audit
- **RDS** is not publicly accessible (`publicly_accessible = false`)

### Note on Storage Encryption

`storage_encrypted = false` is set on the RDS instance because the free-tier `db.t4g.micro` class does not support encryption at rest in this account. For non-free-tier environments (qa, prod), set `storage_encrypted = true`.

## Container Security

- Multi-stage Docker build — final image is Alpine with no build tools
- Application runs as non-root user (`appuser`)
- No secrets are baked into the image — they are injected as environment variables at container start via the SSM-driven `docker run` command
- Trivy scans the image in CI on every push, blocking on CRITICAL and HIGH unfixed vulnerabilities

## ALB Security

- ALB accepts only HTTP (port 80) from the internet. HTTPS (port 443) is not configured in dev; for production, add an ACM certificate and an HTTPS listener with HTTP-to-HTTPS redirect.
- ALB security group (`devops-app-dev-alb-sg`) restricts inbound to TCP 80 only.
- EC2 app security group restricts inbound to port 8000 from the ALB security group only — the EC2 instance is not directly reachable from the internet.

## EC2 Access

The EC2 instance is in a private subnet with no public IP. Access is exclusively via **SSM Session Manager**, which requires no open SSH port or bastion host. This eliminates the attack surface of an open port 22.

## GitHub Actions Hardening

- `permissions` blocks are set to minimum required on every workflow job (`contents: read`, `id-token: write` only where needed)
- Workflow secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) are scoped to the repository and never printed in logs
