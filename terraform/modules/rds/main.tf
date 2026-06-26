locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
    Module      = "rds"
  })
}

resource "random_password" "db" {
  length           = 32
  special          = false
  override_special = ""
}

resource "aws_ssm_parameter" "db_password" {
  name        = "/${var.project}/${var.environment}/rds/password"
  description = "Master password for the ${var.project} ${var.environment} RDS instance."
  type        = "SecureString"
  value       = random_password.db.result

  tags = local.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "db_username" {
  name        = "/${var.project}/${var.environment}/rds/username"
  description = "Master username for the ${var.project} ${var.environment} RDS instance."
  type        = "String"
  value       = var.db_username

  tags = local.common_tags
}

resource "aws_ssm_parameter" "db_name" {
  name        = "/${var.project}/${var.environment}/rds/db_name"
  description = "Database name for the ${var.project} ${var.environment} RDS instance."
  type        = "String"
  value       = var.db_name

  tags = local.common_tags
}

resource "aws_db_subnet_group" "this" {
  name        = "${var.project}-${var.environment}-db-subnet-group"
  description = "Subnet group for ${var.project} ${var.environment} RDS."
  subnet_ids  = var.db_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-db-subnet-group"
  })
}


data "aws_db_instance" "this" {
  db_instance_identifier = "${var.project}-${var.environment}-postgres"
}
