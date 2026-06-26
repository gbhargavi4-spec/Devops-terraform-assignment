locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
    Module      = "ecr"
  })
}

resource "aws_ecr_repository" "this" {
  name                 = "${var.project}-${var.environment}"
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}"
  })
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after ${var.lifecycle_untagged_expiry_days} day(s)"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.lifecycle_untagged_expiry_days
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep the last ${var.lifecycle_tagged_keep_count} tagged images"
        selection = {
          tagStatus      = "tagged"
          tagPrefixList  = ["v", "sha-", "release-"]
          countType      = "imageCountMoreThan"
          countNumber    = var.lifecycle_tagged_keep_count
        }
        action = { type = "expire" }
      }
    ]
  })
}
