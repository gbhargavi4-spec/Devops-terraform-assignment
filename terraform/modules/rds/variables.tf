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

variable "db_subnet_ids" {
  type        = list(string)
  description = "List of private database subnet IDs for the DB subnet group."
}

variable "security_group_id" {
  type        = string
  description = "ID of the RDS security group."
}

variable "monitoring_role_arn" {
  type        = string
  description = "ARN of the IAM role used for RDS enhanced monitoring."
}

variable "db_name" {
  type        = string
  description = "Name of the initial database created on the RDS instance."

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.db_name))
    error_message = "db_name must start with a letter and contain only alphanumeric characters and underscores."
  }
}

variable "db_username" {
  type        = string
  description = "Master username for the RDS instance."

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.db_username))
    error_message = "db_username must start with a letter and contain only alphanumeric characters and underscores."
  }
}

variable "engine_version" {
  type        = string
  description = "PostgreSQL engine version."
  default     = "15.7"
}

variable "instance_class" {
  type        = string
  description = "RDS instance class."
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  type        = number
  description = "Initial allocated storage in GiB."
  default     = 20

  validation {
    condition     = var.allocated_storage >= 20
    error_message = "allocated_storage must be at least 20 GiB for PostgreSQL."
  }
}

variable "max_allocated_storage" {
  type        = number
  description = "Maximum allocated storage for autoscaling in GiB. Set to 0 to disable autoscaling."
  default     = 100
}

variable "multi_az" {
  type        = bool
  description = "Enable Multi-AZ deployment for high availability."
  default     = false
}

variable "backup_retention_period" {
  type        = number
  description = "Number of days to retain automated backups."
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "backup_retention_period must be between 0 and 35. Use 0 to disable automated backups."
  }
}

variable "backup_window" {
  type        = string
  description = "Preferred UTC window for automated backups. Format: hh24:mi-hh24:mi."
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  type        = string
  description = "Preferred UTC window for maintenance. Format: ddd:hh24:mi-ddd:hh24:mi."
  default     = "sun:04:00-sun:05:00"
}

variable "deletion_protection" {
  type        = bool
  description = "Enable deletion protection. Must be disabled before destroying the instance."
  default     = false
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot when the instance is deleted."
  default     = true
}

variable "enable_enhanced_monitoring" {
  type        = bool
  description = "Enable enhanced monitoring with 60-second granularity."
  default     = true
}

variable "monitoring_interval" {
  type        = number
  description = "Enhanced monitoring interval in seconds."
  default     = 60

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "monitoring_interval must be one of: 0, 1, 5, 10, 15, 30, 60."
  }
}

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to all resources in this module."
  default     = {}
}
