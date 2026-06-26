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

variable "region" {
  type        = string
  description = "AWS region where resources are deployed."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones for subnet distribution. Must be 2 or 3."

  validation {
    condition     = length(var.availability_zones) >= 2 && length(var.availability_zones) <= 3
    error_message = "Must specify between 2 and 3 availability zones."
  }
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets. Count must match availability_zones."

  validation {
    condition     = alltrue([for cidr in var.public_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "All public subnet CIDRs must be valid IPv4 CIDR blocks."
  }
}

variable "private_app_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private application subnets. Count must match availability_zones."

  validation {
    condition     = alltrue([for cidr in var.private_app_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "All private application subnet CIDRs must be valid IPv4 CIDR blocks."
  }
}

variable "private_db_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private database subnets. Count must match availability_zones."

  validation {
    condition     = alltrue([for cidr in var.private_db_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "All private database subnet CIDRs must be valid IPv4 CIDR blocks."
  }
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Enable NAT Gateway for private subnet outbound internet connectivity."
  default     = true
}

variable "single_nat_gateway" {
  type        = bool
  description = "Deploy a single NAT Gateway instead of one per AZ. Reduces cost; not recommended for production."
  default     = false
}

variable "enable_flow_logs" {
  type        = bool
  description = "Enable VPC Flow Logs published to CloudWatch Logs."
  default     = true
}

variable "flow_log_retention_days" {
  type        = number
  description = "Retention period in days for VPC Flow Logs."
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.flow_log_retention_days)
    error_message = "flow_log_retention_days must be a valid CloudWatch Logs retention value."
  }
}

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to all resources in this module."
  default     = {}
}
