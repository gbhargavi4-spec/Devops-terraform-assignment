locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
    Module      = "alb"
  })
}

resource "aws_security_group" "alb" {
  name        = "${var.project}-${var.environment}-alb-sg"
  description = "ALB security group - HTTP inbound from internet"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-alb-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
  description       = "HTTP from internet"
}

resource "aws_vpc_security_group_egress_rule" "alb_all_outbound" {
  security_group_id = aws_security_group.alb.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "All outbound traffic"
}

resource "aws_lb" "this" {
  name               = "${var.project}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-alb"
  })
}

resource "aws_lb_target_group" "this" {
  name     = "${var.project}-${var.environment}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-tg"
  })
}

resource "aws_lb_target_group_attachment" "this" {
  target_group_arn = aws_lb_target_group.this.arn
  target_id        = var.ec2_instance_id
  port             = var.app_port
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = local.common_tags
}
