output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway."
  value       = aws_internet_gateway.this.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs ordered by availability zone."
  value       = [for az in var.availability_zones : aws_subnet.public[az].id]
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks ordered by availability zone."
  value       = [for az in var.availability_zones : aws_subnet.public[az].cidr_block]
}

output "private_app_subnet_ids" {
  description = "List of private application subnet IDs ordered by availability zone."
  value       = [for az in var.availability_zones : aws_subnet.private_app[az].id]
}

output "private_app_subnet_cidrs" {
  description = "List of private application subnet CIDR blocks ordered by availability zone."
  value       = [for az in var.availability_zones : aws_subnet.private_app[az].cidr_block]
}

output "private_db_subnet_ids" {
  description = "List of private database subnet IDs ordered by availability zone."
  value       = [for az in var.availability_zones : aws_subnet.private_db[az].id]
}

output "private_db_subnet_cidrs" {
  description = "List of private database subnet CIDR blocks ordered by availability zone."
  value       = [for az in var.availability_zones : aws_subnet.private_db[az].cidr_block]
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs."
  value       = [for ng in aws_nat_gateway.this : ng.id]
}

output "nat_gateway_public_ips" {
  description = "List of Elastic IP addresses associated with NAT Gateways."
  value       = [for eip in aws_eip.nat : eip.public_ip]
}

output "public_route_table_id" {
  description = "ID of the public route table."
  value       = aws_route_table.public.id
}

output "private_app_route_table_ids" {
  description = "List of private application route table IDs."
  value       = [for rt in aws_route_table.private_app : rt.id]
}

output "private_db_route_table_ids" {
  description = "List of private database route table IDs."
  value       = [for rt in aws_route_table.private_db : rt.id]
}

output "availability_zones" {
  description = "List of availability zones used for subnet deployment."
  value       = var.availability_zones
}

output "flow_log_group_name" {
  description = "Name of the CloudWatch Log Group for VPC Flow Logs. Empty string when flow logs are disabled."
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.flow_logs[0].name : ""
}
