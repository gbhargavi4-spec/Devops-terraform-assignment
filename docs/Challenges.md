# Challenges & Solutions

## AWS Provider Version Pinning

**Problem:** Terraform module directories without a pinned provider version downloaded 6.x (`>= 5.0.0`), which renamed `data.aws_region.current.name` to `.region`. Environment roots pinned to `~> 5.0` used `.name`. The mismatch caused `terraform validate` to fail inside modules when initialised independently.

**Solution:** Changed all module `versions.tf` from `>= 5.0.0` to `~> 5.0` and removed all `.terraform/` directories and lock files from module directories. Modules are not deployable roots and must not carry provider lock files.

## Cross-Module State Dependencies

**Problem:** Each environment module is a separate Terraform root. There is no native Terraform mechanism for one root to reference another root's resources.

**Solution:** `terraform_remote_state` data sources with the S3 backend. Each downstream module reads the outputs of its upstream dependencies from the shared state bucket. The state keys follow a predictable convention: `<env>/<module>/terraform.tfstate`, making the dependency graph explicit and auditable.

## Single vs Multi-NAT Routing

**Problem:** When `single_nat_gateway = true`, all AZs must share one route table row, but `for_each` keys had to remain unique. A naïve implementation created one NAT gateway per AZ (expensive) or broke route table associations.

**Solution:** A `az_to_app_rt_key` local maps every AZ to either `"main"` (single-NAT case) or the AZ name itself (multi-NAT case). Route table associations use this mapping, keeping the route table `for_each` key unique while correctly targeting the shared table in the single-NAT path.

## Database Password Rotation

**Problem:** Using a `random_password` resource for the initial password means subsequent `terraform apply` runs would generate a new password and update RDS — a destructive, service-impacting change.

**Solution:** `lifecycle { ignore_changes = [value] }` on the SSM parameter and `lifecycle { ignore_changes = [password] }` on the DB instance. The password is generated once, stored in SSM, and never changed by Terraform again. Rotation is handled out-of-band (e.g., AWS Secrets Manager rotation Lambda or manual SSM update followed by a service restart).

## OIDC Provider Deduplication

**Problem:** The GitHub Actions OIDC provider (`token.actions.githubusercontent.com`) is account-level — creating it in three environment state files would cause conflicts.

**Solution:** `enable_github_oidc = true` only in the `dev` IAM environment. QA and prod IAM roots reference the same provider by ARN using a `data "aws_iam_openid_connect_provider"` lookup instead of recreating it.

## EC2 IMDSv2 Enforcement

**Problem:** The default EC2 IMDS allows IMDSv1 requests, which can be exploited by SSRF attacks to extract IAM credentials.

**Solution:** The EC2 module sets `metadata_options { http_tokens = "required" }`, enforcing IMDSv2 (session-oriented requests with a token header). The CloudWatch Agent and AWS CLI on AL2023 both support IMDSv2 natively.
