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

variable "log_retention_days" {
  type        = number
  description = "Retention period in days for all CloudWatch Log Groups in this environment."
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "log_retention_days must be a valid CloudWatch Logs retention value."
  }
}

variable "ec2_instance_id" {
  type        = string
  description = "EC2 instance ID for CloudWatch alarms and dashboard."
}

variable "rds_identifier" {
  type        = string
  description = "RDS instance identifier for CloudWatch alarms and dashboard."
}

variable "alarm_sns_topic_arn" {
  type        = string
  description = "SNS topic ARN for alarm notifications. Pass empty string to disable notifications."
  default     = ""
}

variable "cpu_alarm_threshold" {
  type        = number
  description = "CPU utilisation percentage that triggers a high-CPU alarm."
  default     = 80
}

variable "rds_storage_alarm_threshold_gb" {
  type        = number
  description = "Free storage in GiB below which an RDS low-storage alarm fires."
  default     = 5
}

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to all resources in this module."
  default     = {}
}
