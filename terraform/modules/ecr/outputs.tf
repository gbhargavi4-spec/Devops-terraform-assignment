output "repository_url" {
  description = "Full URL of the ECR repository."
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  description = "ARN of the ECR repository."
  value       = aws_ecr_repository.this.arn
}

output "repository_name" {
  description = "Name of the ECR repository."
  value       = aws_ecr_repository.this.name
}

output "registry_id" {
  description = "AWS account ID associated with the registry."
  value       = aws_ecr_repository.this.registry_id
}

output "ecr_registry" {
  description = "ECR registry URL without repository name (account.dkr.ecr.region.amazonaws.com)."
  value       = "${aws_ecr_repository.this.registry_id}.dkr.ecr.${split(".", split("/", aws_ecr_repository.this.repository_url)[0])[3]}.amazonaws.com"
}
