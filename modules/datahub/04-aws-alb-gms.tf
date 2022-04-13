resource "aws_security_group" "datahub_gms" {
  name                   = "${var.short_identifier_prefix}datahub-gms-alb"
  description            = "Restricts access to the DataHub Application Load Balancer"
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true

  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Allow inbound HTTP traffic"
    from_port        = local.datahub_gms.port
    to_port          = local.datahub_gms.port
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, {
    "Name" : "DataHub GMS Load Balancer"
  })
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
  subnets            = data.aws_subnet.subnets.*.id
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
