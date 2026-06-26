module "networking" {
  source = "../../modules/networking"

  project     = var.project
  environment = var.environment
  region      = var.aws_region

  vpc_cidr                 = var.vpc_cidr
  availability_zones       = var.availability_zones
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
  enable_nat_gateway       = var.enable_nat_gateway
  single_nat_gateway       = var.single_nat_gateway

  tags = var.tags
}

module "security" {
  source = "../../modules/security"

  project     = var.project
  environment = var.environment

  vpc_id            = module.networking.vpc_id
  vpc_cidr          = module.networking.vpc_cidr_block
  enable_bastion    = var.enable_bastion
  admin_cidr_blocks = var.admin_cidr_blocks
  app_port          = var.app_port

  tags = var.tags
}

module "iam" {
  source = "../../modules/iam"

  project     = var.project
  environment = var.environment

  enable_github_oidc     = var.enable_github_oidc
  github_org             = var.github_org
  github_repo            = var.github_repo
  tfstate_bucket         = var.tfstate_bucket
  tfstate_dynamodb_table = var.tfstate_dynamodb_table

  tags = var.tags
}

module "rds" {
  source = "../../modules/rds"

  project     = var.project
  environment = var.environment

  db_subnet_ids     = module.networking.private_db_subnet_ids
  security_group_id = module.security.rds_security_group_id

  db_name     = var.db_name
  db_username = var.db_username

  engine_version        = "16.4"
  instance_class        = var.rds_instance_class
  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage

  multi_az            = var.rds_multi_az
  deletion_protection = var.rds_deletion_protection
  skip_final_snapshot = var.rds_skip_final_snapshot

  backup_retention_period = 0
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  enable_enhanced_monitoring = true
  monitoring_interval        = 60
  monitoring_role_arn        = module.iam.rds_monitoring_role_arn

  tags = var.tags
}

module "ecr" {
  source = "../../modules/ecr"

  project     = var.project
  environment = var.environment

  image_tag_mutability           = var.ecr_image_tag_mutability
  scan_on_push                   = true
  lifecycle_untagged_expiry_days = var.ecr_lifecycle_untagged_expiry_days
  lifecycle_tagged_keep_count    = var.ecr_lifecycle_tagged_keep_count

  tags = var.tags
}

module "ec2" {
  source = "../../modules/ec2"

  project     = var.project
  environment = var.environment

  subnet_id              = module.networking.private_app_subnet_ids[0]
  security_group_id      = module.security.app_security_group_id
  instance_profile_name  = module.iam.ec2_instance_profile_name
  key_name               = var.key_name

  instance_type    = var.ec2_instance_type
  root_volume_size = var.ec2_root_volume_size
  app_port         = var.app_port

  ecr_registry        = module.ecr.ecr_registry
  ecr_repository_name = module.ecr.repository_name

  db_host              = module.rds.db_host
  db_port              = module.rds.db_port
  db_password_ssm_path = module.rds.db_password_ssm_path
  db_username_ssm_path = module.rds.db_username_ssm_path
  db_name_ssm_path     = module.rds.db_name_ssm_path

  tags = var.tags
}

module "cloudwatch" {
  source = "../../modules/cloudwatch"

  project     = var.project
  environment = var.environment

  ec2_instance_id     = module.ec2.instance_id
  rds_identifier      = module.rds.db_identifier
  log_retention_days  = var.log_retention_days
  alarm_sns_topic_arn = var.alarm_sns_topic_arn
  cpu_alarm_threshold = var.cpu_alarm_threshold

  tags = var.tags
}
