data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.name

  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
    Module      = "iam"
  })
}

data "aws_iam_policy_document" "ec2_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2_ecr" {
  statement {
    sid       = "ECRAuthToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "ECRPull"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
    ]

    resources = [
      "arn:${local.partition}:ecr:${local.region}:${local.account_id}:repository/${var.project}-*",
    ]
  }
}

data "aws_iam_policy_document" "ec2_cloudwatch" {
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
    ]

    resources = [
      "arn:${local.partition}:logs:${local.region}:${local.account_id}:log-group:/aws/${var.project}/${var.environment}*",
      "arn:${local.partition}:logs:${local.region}:${local.account_id}:log-group:/aws/${var.project}/${var.environment}*:*",
    ]
  }

  statement {
    sid       = "CloudWatchMetrics"
    effect    = "Allow"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["${var.project}/${var.environment}"]
    }
  }
}

data "aws_iam_policy_document" "ec2_ssm_parameters" {
  statement {
    sid    = "SSMParameterRead"
    effect = "Allow"

    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]

    resources = [
      "arn:${local.partition}:ssm:${local.region}:${local.account_id}:parameter/${var.project}/${var.environment}/*",
    ]
  }
}

resource "aws_iam_role" "ec2" {
  name               = "${var.project}-${var.environment}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-ec2-role"
  })
}

resource "aws_iam_policy" "ec2_ecr" {
  name        = "${var.project}-${var.environment}-ec2-ecr-policy"
  description = "Allows EC2 to pull container images from project ECR repositories."
  policy      = data.aws_iam_policy_document.ec2_ecr.json

  tags = local.common_tags
}

resource "aws_iam_policy" "ec2_cloudwatch" {
  name        = "${var.project}-${var.environment}-ec2-cloudwatch-policy"
  description = "Allows EC2 to write logs and metrics to CloudWatch."
  policy      = data.aws_iam_policy_document.ec2_cloudwatch.json

  tags = local.common_tags
}

resource "aws_iam_policy" "ec2_ssm_parameters" {
  name        = "${var.project}-${var.environment}-ec2-ssm-policy"
  description = "Allows EC2 to read SSM Parameter Store values scoped to project and environment."
  policy      = data.aws_iam_policy_document.ec2_ssm_parameters.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ec2_ecr" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.ec2_ecr.arn
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.ec2_cloudwatch.arn
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_parameters" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.ec2_ssm_parameters.arn
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_core" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2.name

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-ec2-profile"
  })
}

data "aws_iam_policy_document" "rds_monitoring_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_monitoring" {
  name               = "${var.project}-${var.environment}-rds-monitoring-role"
  assume_role_policy = data.aws_iam_policy_document.rds_monitoring_trust.json

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-rds-monitoring-role"
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.enable_github_oidc ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = merge(local.common_tags, {
    Name = "github-actions-oidc"
  })
}

data "aws_iam_policy_document" "github_actions_trust" {
  count = var.enable_github_oidc ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github[0].arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:*"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "github_actions_ecr" {
  count = var.enable_github_oidc ? 1 : 0

  statement {
    sid       = "ECRAuthToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "ECRPushPull"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchDeleteImage",
      "ecr:TagResource",
    ]

    resources = [
      "arn:${local.partition}:ecr:${local.region}:${local.account_id}:repository/${var.project}-*",
    ]
  }
}

data "aws_iam_policy_document" "github_actions_terraform" {
  count = var.enable_github_oidc ? 1 : 0

  statement {
    sid    = "TerraformStateBucket"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]

    resources = [
      "arn:${local.partition}:s3:::${var.tfstate_bucket}",
      "arn:${local.partition}:s3:::${var.tfstate_bucket}/*",
    ]
  }

  statement {
    sid    = "TerraformStateLock"
    effect = "Allow"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable",
    ]

    resources = [
      "arn:${local.partition}:dynamodb:${local.region}:${local.account_id}:table/${var.tfstate_dynamodb_table}",
    ]
  }
}

data "aws_iam_policy_document" "github_actions_deploy" {
  count = var.enable_github_oidc ? 1 : 0

  statement {
    sid    = "SSMRunCommand"
    effect = "Allow"

    actions = [
      "ssm:SendCommand",
      "ssm:GetCommandInvocation",
      "ssm:ListCommandInvocations",
    ]

    resources = [
      "arn:${local.partition}:ssm:${local.region}::document/AWS-RunShellScript",
      "arn:${local.partition}:ec2:${local.region}:${local.account_id}:instance/*",
    ]
  }

  statement {
    sid    = "EC2Describe"
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "SSMParameterWrite"
    effect = "Allow"

    actions = [
      "ssm:PutParameter",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:DeleteParameter",
    ]

    resources = [
      "arn:${local.partition}:ssm:${local.region}:${local.account_id}:parameter/${var.project}/*",
    ]
  }
}

resource "aws_iam_role" "github_actions" {
  count = var.enable_github_oidc ? 1 : 0

  name               = "${var.project}-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust[0].json

  tags = merge(local.common_tags, {
    Name = "${var.project}-github-actions-role"
  })
}

resource "aws_iam_policy" "github_actions_ecr" {
  count = var.enable_github_oidc ? 1 : 0

  name        = "${var.project}-github-actions-ecr-policy"
  description = "Allows GitHub Actions to push and pull container images from project ECR repositories."
  policy      = data.aws_iam_policy_document.github_actions_ecr[0].json

  tags = local.common_tags
}

resource "aws_iam_policy" "github_actions_terraform" {
  count = var.enable_github_oidc ? 1 : 0

  name        = "${var.project}-github-actions-terraform-policy"
  description = "Allows GitHub Actions to read and write Terraform state in S3 and acquire DynamoDB locks."
  policy      = data.aws_iam_policy_document.github_actions_terraform[0].json

  tags = local.common_tags
}

resource "aws_iam_policy" "github_actions_deploy" {
  count = var.enable_github_oidc ? 1 : 0

  name        = "${var.project}-github-actions-deploy-policy"
  description = "Allows GitHub Actions to trigger deployments via SSM Run Command and manage environment parameters."
  policy      = data.aws_iam_policy_document.github_actions_deploy[0].json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "github_actions_ecr" {
  count = var.enable_github_oidc ? 1 : 0

  role       = aws_iam_role.github_actions[0].name
  policy_arn = aws_iam_policy.github_actions_ecr[0].arn
}

resource "aws_iam_role_policy_attachment" "github_actions_terraform" {
  count = var.enable_github_oidc ? 1 : 0

  role       = aws_iam_role.github_actions[0].name
  policy_arn = aws_iam_policy.github_actions_terraform[0].arn
}

resource "aws_iam_role_policy_attachment" "github_actions_deploy" {
  count = var.enable_github_oidc ? 1 : 0

  role       = aws_iam_role.github_actions[0].name
  policy_arn = aws_iam_policy.github_actions_deploy[0].arn
}
