variable "project" {
  type        = string
  description = "Project name used in resource naming and tagging."

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "Project name must contain only lowercase alphanumeric characters and hyphens."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment."

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "Environment must be one of: dev, qa, prod."
  }
}

variable "subnet_id" {
  type        = string
  description = "ID of the private application subnet where the instance is placed."
}

variable "security_group_id" {
  type        = string
  description = "Security group ID assigned to the application instance."
}

variable "instance_profile_name" {
  type        = string
  description = "Name of the IAM instance profile attached to the EC2 instance."
}

variable "key_name" {
  type        = string
  description = "Name of the EC2 key pair for SSH access. Leave empty to disable key-based access."
  default     = ""
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type."
  default     = "t3.micro"
}

variable "root_volume_size" {
  type        = number
  description = "Size of the root EBS volume in GiB."
  default     = 20

  validation {
    condition     = var.root_volume_size >= 20
    error_message = "Root volume must be at least 20 GiB."
  }
}

variable "app_port" {
  type        = number
  description = "TCP port the application listens on inside the container."
  default     = 8000
}

variable "ecr_registry" {
  type        = string
  description = "ECR registry URL (account.dkr.ecr.region.amazonaws.com)."
}

variable "ecr_repository_name" {
  type        = string
  description = "Name of the ECR repository holding the application image."
}

variable "db_host" {
  type        = string
  description = "Hostname of the RDS instance."
}

variable "db_port" {
  type        = number
  description = "Port the RDS instance listens on."
  default     = 5432
}

variable "db_password_ssm_path" {
  type        = string
  description = "SSM Parameter Store path for the database password (SecureString)."
}

variable "db_username_ssm_path" {
  type        = string
  description = "SSM Parameter Store path for the database username."
}

variable "db_name_ssm_path" {
  type        = string
  description = "SSM Parameter Store path for the database name."
}

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to all resources in this module."
  default     = {}
}
