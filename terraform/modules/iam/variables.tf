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

variable "github_org" {
  type        = string
  description = "GitHub organisation or user that owns the repository."
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name used to scope the OIDC trust condition."
}

variable "tfstate_bucket" {
  type        = string
  description = "S3 bucket that holds Terraform remote state for all layers."
}

variable "tfstate_dynamodb_table" {
  type        = string
  description = "DynamoDB table used for Terraform state locking."
}

variable "enable_github_oidc" {
  type        = bool
  description = "Create the GitHub Actions OIDC provider and federation role. Enable in exactly one environment per AWS account to avoid duplicate provider errors."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to all resources in this module."
  default     = {}
}
