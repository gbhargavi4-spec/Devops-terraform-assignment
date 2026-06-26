output "app_log_group_name" {
  description = "Name of the application CloudWatch Log Group."
  value       = aws_cloudwatch_log_group.app.name
}

output "ec2_system_log_group_name" {
  description = "Name of the EC2 system CloudWatch Log Group."
  value       = aws_cloudwatch_log_group.ec2_system.name
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard."
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "ec2_cpu_alarm_arn" {
  description = "ARN of the EC2 CPU high alarm."
  value       = aws_cloudwatch_metric_alarm.ec2_cpu_high.arn
}

output "rds_cpu_alarm_arn" {
  description = "ARN of the RDS CPU high alarm."
  value       = aws_cloudwatch_metric_alarm.rds_cpu_high.arn
}

output "rds_storage_alarm_arn" {
  description = "ARN of the RDS low storage alarm."
  value       = aws_cloudwatch_metric_alarm.rds_storage_low.arn
}
