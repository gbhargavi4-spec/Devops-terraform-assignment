output "vpc_id" {
  description = "VPC ID."
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.networking.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "Private application subnet IDs."
  value       = module.networking.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "Private database subnet IDs."
  value       = module.networking.private_db_subnet_ids
}

output "app_security_group_id" {
  description = "Application security group ID."
  value       = module.security.app_security_group_id
}

output "rds_security_group_id" {
  description = "RDS security group ID."
  value       = module.security.rds_security_group_id
}

output "ec2_instance_profile_name" {
  description = "EC2 IAM instance profile name."
  value       = module.iam.ec2_instance_profile_name
}

output "github_actions_role_arn" {
  description = "GitHub Actions OIDC role ARN."
  value       = module.iam.github_actions_role_arn
}

output "db_identifier" {
  description = "RDS instance identifier."
  value       = module.rds.db_identifier
}

output "db_host" {
  description = "RDS instance hostname."
  value       = module.rds.db_host
}

output "db_password_ssm_path" {
  description = "SSM path for the database password."
  value       = module.rds.db_password_ssm_path
}

output "ecr_repository_url" {
  description = "ECR repository URL."
  value       = module.ecr.repository_url
}

output "ecr_registry" {
  description = "ECR registry URL."
  value       = module.ecr.ecr_registry
}

output "ec2_instance_id" {
  description = "EC2 instance ID."
  value       = module.ec2.instance_id
}

output "ec2_private_ip" {
  description = "EC2 instance private IP."
  value       = module.ec2.private_ip
}

output "cloudwatch_dashboard_name" {
  description = "CloudWatch dashboard name."
  value       = module.cloudwatch.dashboard_name
}

output "app_log_group_name" {
  description = "Application CloudWatch log group name."
  value       = module.cloudwatch.app_log_group_name
}
