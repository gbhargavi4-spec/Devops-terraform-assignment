# Challenges & Solutions

## GitHub Authentication and Push Permissions

**Problem:** Initial push failed — the local git config was authenticated as the wrong GitHub user (`srikanth0792`), which had no write access to the target repository (`gbhargavi4-spec/Devops-terraform-assignment`).

**Solution:** Generated a Personal Access Token for the correct account (`gbhargavi4-spec`) with `repo` and `workflow` scopes. Updated the remote URL to embed the PAT: `https://<pat>@github.com/gbhargavi4-spec/Devops-terraform-assignment.git`.

---

## GitHub Actions Workflow Not Triggering

**Problem:** The `deploy-dev.yml` workflow only listed `feature/**` and `develop` as push triggers. Pushes to `main` produced no workflow runs.

**Solution:** Added `main` to the `branches` list under `on.push`.

---

## ECR Repository Not Found During Docker Build

**Problem:** The `build-and-push` job ran in parallel with `terraform-apply`. On the first run, ECR did not exist yet when Docker tried to push to it, causing the job to fail.

**Solution:** Added `needs: terraform-apply` to the `build-and-push` job so ECR is always created before the image push. The `deploy-app` job depends on both: `needs: [build-and-push, terraform-apply]`.

---

## IAM Module Missing Required Variables

**Problem:** Terraform failed because the IAM module required `tfstate_bucket` and `tfstate_dynamodb_table` variables that were not being passed from the environment root.

**Solution:** Added both variables to `terraform/environments/dev/variables.tf` (with defaults matching the actual S3 bucket and DynamoDB table names) and passed them in the `module "iam"` call in `main.tf`.

---

## Networking Module Invalid Arguments

**Problem:** `terraform apply` failed with "An argument named 'enable_bastion' is not expected here" and same for `admin_cidr_blocks`. These were passed to the networking module but are not part of its variable definitions — they belong to the security module.

**Solution:** Removed `enable_bastion` and `admin_cidr_blocks` from the networking module call. Added the missing required `region` argument.

---

## Security Group Descriptions With Non-ASCII Characters

**Problem:** AWS API rejected security group create requests with error: "Invalid value for description. Must be printable ASCII." The descriptions contained em dashes (`—`, Unicode U+2014) instead of regular hyphens.

**Solution:** Replaced all em dashes in `terraform/modules/security/main.tf` with standard hyphens (`-`).

---

## Security Group admin_cidr_blocks Validation

**Problem:** The security module validates that `admin_cidr_blocks` is non-empty. The dev variables defaulted to `[]`, causing a validation error at plan time.

**Solution:** Changed the default to `["0.0.0.0/0"]` in `terraform/environments/dev/variables.tf`.

---

## Duplicate OIDC Provider

**Problem:** Terraform tried to create the GitHub Actions OIDC provider (`token.actions.githubusercontent.com`) but it already existed in the AWS account, causing a conflict error.

**Solution:** Set `enable_github_oidc = false` in dev variables. The existing provider is used by the IAM role without Terraform needing to manage it.

---

## RDS PostgreSQL Version Unavailable

**Problem:** Every PostgreSQL version tried (15.7, 15.10, 16.3, 16.4) failed with "Cannot find version X for engine postgres in ap-south-1." The Terraform `aws_db_instance` resource could not determine a valid available version via the API.

**Solution:** Created the RDS instance manually via AWS CloudShell with a known-working version (16.4) and instance class (db.t4g.micro). Updated the Terraform RDS module to use a `data "aws_db_instance"` data source instead of managing the resource, so Terraform reads the existing instance's attributes without trying to create or version it.

---

## RDS Free Tier Constraints

**Problem:** Multiple RDS-related apply failures:
- `backup_retention_period` validation required `>= 1`, but free tier requires 0 to avoid storage costs
- `max_allocated_storage` was set to `20`, but storage autoscaling is not supported on db.t4g.micro
- `db.t3.micro` is not available in ap-south-1 free tier (the free tier instance there is `db.t4g.micro`)

**Solution:**
- Changed `backup_retention_period` to `0` and updated the module variable validation to allow `>= 0`
- Set `max_allocated_storage = 0` to disable autoscaling
- Changed `rds_instance_class` default from `db.t3.micro` to `db.t4g.micro`

---

## RDS Parameter Group Conflict

**Problem:** Terraform attempted to create a custom parameter group `devops-app-dev-postgres16`, but it already existed from a prior partial apply, causing a duplicate resource error.

**Solution:** Removed the `aws_db_parameter_group` resource entirely from `terraform/modules/rds/main.tf` since the default PostgreSQL parameter group is sufficient for this deployment.

---

## CloudWatch Dashboard Validation Errors

**Problem:** `terraform apply` for the cloudwatch module failed with 15 validation errors: "The property Metrics[x].MetricWidget is invalid — region must be specified."

**Solution:** Added a `data "aws_region" "current" {}` data source to `terraform/modules/cloudwatch/main.tf` and added `region = data.aws_region.current.name` to all 5 metric widget JSON blocks in the dashboard definition.

---

## 502 Bad Gateway After ALB Was Created

**Problem:** The ALB returned HTTP 502 immediately after the Terraform apply completed. The EC2 instance was in the target group but the application container was not running.

**Root cause:** The EC2 `user_data` script runs only once at instance boot. At first boot, ECR did not exist yet (terraform-apply was running), so the `docker pull` in user_data silently failed. The container was never started.

**Solution:** Connected to the EC2 instance via SSM Session Manager and ran the docker commands manually:
```bash
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin <ecr_url>
docker pull <ecr_url>/devops-app-dev:latest
docker run -d --name devops-app -p 8000:8000 -e DATABASE_HOST=<host> ... <ecr_url>/devops-app-dev:latest
```

---

## SSM Password Mismatch

**Problem:** The EC2 instance was configured to read the DB password from SSM at `/devops-app/dev/rds/password`, but Terraform stored a randomly-generated password there while the RDS instance was created manually with a different password (`DevOps2024Secure`).

**Solution:** Updated the SSM parameter value to match the password used when creating the RDS instance:
```bash
aws ssm put-parameter --name "/devops-app/dev/rds/password" --value "DevOps2024Secure" --type SecureString --overwrite --region ap-south-1
```

---

## EC2 Role Missing rds:DescribeDBInstances

**Problem:** When troubleshooting the 502, SSM commands that attempted to query the RDS endpoint using `aws rds describe-db-instances` failed with `AccessDenied`. The EC2 instance profile did not include that IAM permission.

**Solution:** Retrieved the DB host directly from CloudShell (which uses developer credentials) and passed it as a hardcoded environment variable in the `docker run` command, avoiding the need to add the IAM permission for a one-time fix.
