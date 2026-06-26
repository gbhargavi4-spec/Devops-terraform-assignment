locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
    Module      = "security"
  })
}

resource "aws_security_group" "app" {
  name        = "${var.project}-${var.environment}-app-sg"
  description = "Application EC2 instances — HTTP/HTTPS inbound, all outbound."
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-app-sg"
    Role = "application"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.project}-${var.environment}-rds-sg"
  description = "PostgreSQL RDS — inbound from application tier only, no outbound."
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-rds-sg"
    Role = "database"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "bastion" {
  count = var.enable_bastion ? 1 : 0

  name        = "${var.project}-${var.environment}-bastion-sg"
  description = "Bastion host — SSH inbound from admin CIDRs, SSH outbound to VPC."
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-bastion-sg"
    Role = "bastion"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "monitoring" {
  name        = "${var.project}-${var.environment}-monitoring-sg"
  description = "Monitoring stack — Grafana from admin CIDRs, Prometheus and Node Exporter from VPC."
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-monitoring-sg"
    Role = "monitoring"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_http" {
  security_group_id = aws_security_group.app.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
  description       = "HTTP from internet"

  tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-app-http" })
}

resource "aws_vpc_security_group_ingress_rule" "app_https" {
  security_group_id = aws_security_group.app.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
  description       = "HTTPS from internet"

  tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-app-https" })
}

resource "aws_vpc_security_group_ingress_rule" "app_port_internal" {
  security_group_id = aws_security_group.app.id
  ip_protocol       = "tcp"
  from_port         = var.app_port
  to_port           = var.app_port
  cidr_ipv4         = var.vpc_cidr
  description       = "Application port from VPC for internal health checks"

  tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-app-port-internal" })
}

resource "aws_vpc_security_group_ingress_rule" "app_node_exporter_from_monitoring" {
  security_group_id            = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = 9100
  to_port                      = 9100
  referenced_security_group_id = aws_security_group.monitoring.id
  description                  = "Node Exporter scraping from monitoring instances"

  tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-app-node-exporter" })
}

resource "aws_vpc_security_group_ingress_rule" "app_ssh_from_bastion" {
  count = var.enable_bastion ? 1 : 0

  security_group_id            = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  referenced_security_group_id = aws_security_group.bastion[0].id
  description                  = "SSH from bastion host only"

  tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-app-ssh-bastion" })
}

resource "aws_vpc_security_group_ingress_rule" "app_ssh_direct" {
  for_each = !var.enable_bastion && var.enable_direct_ssh ? toset(var.admin_cidr_blocks) : toset([])

  security_group_id = aws_security_group.app.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = each.value
  description       = "Direct SSH from admin CIDR ${each.value}"

  tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-app-ssh-direct-${replace(each.value, "/", "-")}" })
}

resource "aws_vpc_security_group_egress_rule" "app_all_outbound" {
  security_group_id = aws_security_group.app.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "All outbound traffic"

  tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-app-egress-all" })
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_app" {
  security_group_id            = aws_security_group.rds.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.app.id
  description                  = "PostgreSQL from application instances"

  tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-rds-from-app" })
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  for_each = var.enable_bastion ? toset(var.admin_cidr_blocks) : toset([])

  security_group_id = aws_security_group.bastion[0].id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = each.value
  description       = "SSH from admin CIDR ${each.value}"

  tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-bastion-ssh-${replace(each.value, "/", "-")}" })
}

resource "aws_vpc_security_group_egress_rule" "bastion_ssh_to_vpc" {
  count = var.enable_bastion ? 1 : 0

  security_group_id = aws_security_group.bastion[0].id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.vpc_cidr
  description       = "SSH forwarding to private instances in VPC"

  tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-bastion-ssh-egress" })
}

resource "aws_vpc_security_group_egress_rule" "bastion_https_outbound" {
  count = var.enable_bastion ? 1 : 0

  security_group_id = aws_security_group.bastion[0].id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
  description       = "HTTPS outbound for package updates and AWS API calls"

  tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-bastion-https-egress" })
}

resource "aws_vpc_security_group_ingress_rule" "monitoring_grafana" {
  for_each = toset(var.admin_cidr_blocks)

  security_group_id = aws_security_group.monitoring.id
  ip_protocol       = "tcp"
  from_port         = 3000
  to_port           = 3000
  cidr_ipv4         = each.value
  description       = "Grafana UI from admin CIDR ${each.value}"

  tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-monitoring-grafana-${replace(each.value, "/", "-")}" })
}

resource "aws_vpc_security_group_ingress_rule" "monitoring_prometheus" {
  security_group_id = aws_security_group.monitoring.id
  ip_protocol       = "tcp"
  from_port         = 9090
  to_port           = 9090
  cidr_ipv4         = var.vpc_cidr
  description       = "Prometheus from VPC for internal federation and rules evaluation"

  tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-monitoring-prometheus" })
}

resource "aws_vpc_security_group_ingress_rule" "monitoring_node_exporter" {
  security_group_id = aws_security_group.monitoring.id
  ip_protocol       = "tcp"
  from_port         = 9100
  to_port           = 9100
  cidr_ipv4         = var.vpc_cidr
  description       = "Node Exporter from VPC"

  tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-monitoring-node-exporter" })
}

resource "aws_vpc_security_group_ingress_rule" "monitoring_ssh" {
  for_each = toset(var.admin_cidr_blocks)

  security_group_id = aws_security_group.monitoring.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = each.value
  description       = "SSH from admin CIDR ${each.value}"

  tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-monitoring-ssh-${replace(each.value, "/", "-")}" })
}

resource "aws_vpc_security_group_egress_rule" "monitoring_all_outbound" {
  security_group_id = aws_security_group.monitoring.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "All outbound traffic for target scraping and alerting"

  tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-monitoring-egress-all" })
}
