variable "project" {
  type        = string
  description = "Project name used in resource naming and tagging."
}

variable "environment" {
  type        = string
  description = "Deployment environment."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the ALB is created."
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs for the ALB."
}

variable "ec2_instance_id" {
  type        = string
  description = "EC2 instance ID to register as the ALB target."
}

variable "app_port" {
  type        = number
  description = "Port the application listens on."
  default     = 8000
}

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to all resources."
  default     = {}
}
