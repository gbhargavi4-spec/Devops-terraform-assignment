output "app_security_group_id" {
  description = "ID of the application EC2 security group."
  value       = aws_security_group.app.id
}

output "app_security_group_name" {
  description = "Name of the application EC2 security group."
  value       = aws_security_group.app.name
}

output "rds_security_group_id" {
  description = "ID of the RDS PostgreSQL security group."
  value       = aws_security_group.rds.id
}

output "rds_security_group_name" {
  description = "Name of the RDS PostgreSQL security group."
  value       = aws_security_group.rds.name
}

output "bastion_security_group_id" {
  description = "ID of the bastion host security group. Empty string when bastion is disabled."
  value       = var.enable_bastion ? aws_security_group.bastion[0].id : ""
}

output "monitoring_security_group_id" {
  description = "ID of the monitoring stack security group."
  value       = aws_security_group.monitoring.id
}

output "monitoring_security_group_name" {
  description = "Name of the monitoring stack security group."
  value       = aws_security_group.monitoring.name
}
