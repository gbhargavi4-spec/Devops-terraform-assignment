output "db_identifier" {
  description = "Identifier of the RDS instance."
  value       = aws_db_instance.this.identifier
}

output "db_endpoint" {
  description = "Connection endpoint of the RDS instance (host:port)."
  value       = aws_db_instance.this.endpoint
}

output "db_host" {
  description = "Hostname of the RDS instance."
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "Port the RDS instance listens on."
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Name of the initial database."
  value       = aws_db_instance.this.db_name
}

output "db_arn" {
  description = "ARN of the RDS instance."
  value       = aws_db_instance.this.arn
}

output "db_password_ssm_path" {
  description = "SSM Parameter Store path for the database master password."
  value       = aws_ssm_parameter.db_password.name
}

output "db_username_ssm_path" {
  description = "SSM Parameter Store path for the database master username."
  value       = aws_ssm_parameter.db_username.name
}

output "db_name_ssm_path" {
  description = "SSM Parameter Store path for the database name."
  value       = aws_ssm_parameter.db_name.name
}

output "subnet_group_name" {
  description = "Name of the DB subnet group."
  value       = aws_db_subnet_group.this.name
}
