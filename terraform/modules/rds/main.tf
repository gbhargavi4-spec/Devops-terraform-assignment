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

resource "aws_db_parameter_group" "this" {
  name        = "${var.project}-${var.environment}-pg16"
  family      = "postgres16"
  description = "Custom parameter group for ${var.project} ${var.environment} PostgreSQL 16."

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_duration"
    value = "0"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-pg16"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "this" {
  identifier = "${var.project}-${var.environment}-postgres"

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.security_group_id]
  parameter_group_name   = aws_db_parameter_group.this.name

  multi_az               = var.multi_az
  publicly_accessible    = false
  deletion_protection    = var.deletion_protection
  skip_final_snapshot    = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project}-${var.environment}-final-snapshot"

  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window
  copy_tags_to_snapshot   = true

  monitoring_interval = var.enable_enhanced_monitoring ? var.monitoring_interval : 0
  monitoring_role_arn = var.enable_enhanced_monitoring ? var.monitoring_role_arn : null

  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  auto_minor_version_upgrade = true
  apply_immediately          = false

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-postgres"
  })

  lifecycle {
    prevent_destroy       = false
    ignore_changes        = [password]
  }
}
