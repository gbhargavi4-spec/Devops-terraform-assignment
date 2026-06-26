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

variable "image_tag_mutability" {
  type        = string
  description = "Image tag mutability. Use IMMUTABLE in production to prevent tag overwriting."
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  type        = bool
  description = "Enable automatic vulnerability scanning on image push."
  default     = true
}

variable "lifecycle_untagged_expiry_days" {
  type        = number
  description = "Number of days after which untagged images are expired."
  default     = 1
}

variable "lifecycle_tagged_keep_count" {
  type        = number
  description = "Number of tagged images to retain per tag prefix."
  default     = 10
}

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to all resources in this module."
  default     = {}
}
