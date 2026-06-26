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

variable "vpc_id" {
  type        = string
  description = "ID of the VPC in which security groups are created."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block of the VPC used for intra-VPC rules."

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "admin_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks permitted for administrative SSH and monitoring UI access."

  validation {
    condition     = length(var.admin_cidr_blocks) > 0
    error_message = "At least one admin CIDR block must be specified."
  }

  validation {
    condition     = alltrue([for cidr in var.admin_cidr_blocks : can(cidrhost(cidr, 0))])
    error_message = "All admin CIDR blocks must be valid IPv4 CIDR notation."
  }
}

variable "app_port" {
  type        = number
  description = "TCP port the application container listens on."
  default     = 8080

  validation {
    condition     = var.app_port > 0 && var.app_port < 65536
    error_message = "app_port must be between 1 and 65535."
  }
}

variable "enable_bastion" {
  type        = bool
  description = "Create a bastion security group and restrict app SSH to it. When false, no SSH is opened on the app SG."
  default     = false
}

variable "enable_direct_ssh" {
  type        = bool
  description = "Open SSH on the app security group directly from admin_cidr_blocks. Mutually exclusive with enable_bastion; only effective when enable_bastion is false."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to all resources in this module."
  default     = {}
}
