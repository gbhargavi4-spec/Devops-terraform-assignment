variable "aws_region" {
  type        = string
  description = "AWS region for all resources."
  default     = "ap-south-1"
}

variable "project" {
  type        = string
  description = "Project name used in resource naming and tagging."
  default     = "devops-app"
}

variable "environment" {
  type        = string
  description = "Deployment environment."
  default     = "dev"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
  default     = "10.0.0.0/20"
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones to deploy subnets into."
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets."
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_app_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private application subnets."
  default     = ["10.0.4.0/24", "10.0.5.0/24"]
}

variable "private_db_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private database subnets."
  default     = ["10.0.8.0/24", "10.0.9.0/24"]
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Deploy a NAT Gateway for private subnet internet access."
  default     = true
}

variable "single_nat_gateway" {
  type        = bool
  description = "Use a single NAT Gateway shared across all AZs."
  default     = true
}

variable "enable_bastion" {
  type        = bool
  description = "Deploy a bastion security group."
  default     = false
}

variable "admin_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks permitted to reach the bastion on port 22."
  default     = []
}

variable "github_org" {
  type        = string
  description = "GitHub organisation name for OIDC trust policy."
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name for OIDC trust policy."
}

variable "enable_github_oidc" {
  type        = bool
  description = "Create the GitHub Actions OIDC provider. Set true only in one environment per account."
  default     = true
}

variable "db_name" {
  type        = string
  description = "Name of the initial PostgreSQL database."
  default     = "devopsapp"
}

variable "db_username" {
  type        = string
  description = "Master username for the RDS instance."
  default     = "devopsapp"
}

variable "rds_instance_class" {
  type        = string
  description = "RDS instance class."
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  type        = number
  description = "Initial allocated storage in GiB."
  default     = 20
}

variable "rds_max_allocated_storage" {
  type        = number
  description = "Maximum storage for autoscaling in GiB."
  default     = 100
}

variable "rds_multi_az" {
  type        = bool
  description = "Enable Multi-AZ for RDS."
  default     = false
}

variable "rds_deletion_protection" {
  type        = bool
  description = "Enable deletion protection on the RDS instance."
  default     = false
}

variable "rds_skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot when destroying the RDS instance."
  default     = true
}

variable "ec2_instance_type" {
  type        = string
  description = "EC2 instance type for the application server."
  default     = "t3.micro"
}

variable "ec2_root_volume_size" {
  type        = number
  description = "Root EBS volume size in GiB."
  default     = 20
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name for SSH. Leave empty to disable."
  default     = ""
}

variable "app_port" {
  type        = number
  description = "Port the application container listens on."
  default     = 8000
}

variable "ecr_image_tag_mutability" {
  type        = string
  description = "ECR image tag mutability setting."
  default     = "MUTABLE"
}

variable "ecr_lifecycle_untagged_expiry_days" {
  type        = number
  description = "Days after which untagged images are expired."
  default     = 1
}

variable "ecr_lifecycle_tagged_keep_count" {
  type        = number
  description = "Number of tagged images to retain."
  default     = 20
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch Log Group retention in days."
  default     = 30
}

variable "alarm_sns_topic_arn" {
  type        = string
  description = "SNS topic ARN for CloudWatch alarm notifications. Empty string disables notifications."
  default     = ""
}

variable "cpu_alarm_threshold" {
  type        = number
  description = "CPU percentage threshold that triggers the high-CPU alarm."
  default     = 80
}

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to all resources."
  default     = {}
}
