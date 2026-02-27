resource "aws_security_group" "datahub_gms" {
  name                   = "${var.short_identifier_prefix}datahub-gms-alb"
  description            = "Restricts access to the DataHub Application Load Balancer"
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true

  tags = merge(var.tags, {
    "Name" : "DataHub GMS Load Balancer"
  })
}

resource "aws_security_group_rule" "datahub_gms_egress" {
  type              = "egress"
  description       = "Allow all outbound traffic"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.datahub_gms.id
}


locals {
  security_groups = {
    frontend_react_security_group_id = module.datahub_frontend_react.security_group_id
    mae_consumer_security_group_id   = module.datahub_mae_consumer.security_group_id
    mce_consumer_security_group_id   = module.datahub_mce_consumer.security_group_id
    actions_security_group_id        = module.datahub_actions.security_group_id
  }
}

resource "aws_security_group_rule" "datahub_gms_ingress" {
  for_each = local.security_groups

  type                     = "ingress"
  description              = "Allow inbound HTTP traffic from Datahub containers"
  from_port                = local.datahub_gms.port
  to_port                  = local.datahub_gms.port
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = aws_security_group.datahub_gms.id
}

resource "aws_alb_target_group" "datahub_gms" {
  name        = "${var.short_identifier_prefix}datahub-gms"
  port        = local.datahub_gms.port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    protocol = "HTTP"
    path     = "/health"
    port     = local.datahub_gms.port
    interval = 60
  }
}

resource "aws_alb" "datahub_gms" {
  name               = "${var.short_identifier_prefix}datahub-gms"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.datahub_gms.id]
  subnets            = var.vpc_subnet_ids
}

resource "aws_alb_listener" "datahub_gms" {
  load_balancer_arn = aws_alb.datahub_gms.arn
  port              = local.datahub_gms.port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.datahub_gms.arn
  }
}
