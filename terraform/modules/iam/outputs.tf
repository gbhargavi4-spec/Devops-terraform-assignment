output "ec2_instance_role_arn" {
  description = "ARN of the IAM role attached to EC2 instances."
  value       = aws_iam_role.ec2.arn
}

output "ec2_instance_role_name" {
  description = "Name of the IAM role attached to EC2 instances."
  value       = aws_iam_role.ec2.name
}

output "ec2_instance_profile_arn" {
  description = "ARN of the EC2 instance profile."
  value       = aws_iam_instance_profile.ec2.arn
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile."
  value       = aws_iam_instance_profile.ec2.name
}

output "rds_monitoring_role_arn" {
  description = "ARN of the RDS enhanced monitoring IAM role."
  value       = aws_iam_role.rds_monitoring.arn
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions OIDC federation role. Empty string when enable_github_oidc is false."
  value       = var.enable_github_oidc ? aws_iam_role.github_actions[0].arn : ""
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider. Empty string when enable_github_oidc is false."
  value       = var.enable_github_oidc ? aws_iam_openid_connect_provider.github[0].arn : ""
}
