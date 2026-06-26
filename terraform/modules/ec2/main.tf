locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
    Module      = "ec2"
  })
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_region" "current" {}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = var.instance_profile_name
  key_name               = var.key_name

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh.tpl", {
    project              = var.project
    environment          = var.environment
    aws_region           = data.aws_region.current.name
    ecr_registry         = var.ecr_registry
    ecr_repository_name  = var.ecr_repository_name
    app_port             = var.app_port
    db_password_ssm_path = var.db_password_ssm_path
    db_username_ssm_path = var.db_username_ssm_path
    db_name_ssm_path     = var.db_name_ssm_path
    db_host              = var.db_host
    db_port              = var.db_port
  }))

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  monitoring = true

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-app"
  })

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [ami, user_data]
  }
}
