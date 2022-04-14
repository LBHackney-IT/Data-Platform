resource "aws_security_group" "datahub_frontend_react" {
  name                   = "${var.short_identifier_prefix}datahub-frontend-alb"
  description            = "Restricts access to the DataHub Frontend React Application Load Balancer"
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
    description      = "Allow inbound HTTP traffic on Datahub Frontend port"
    from_port        = local.datahub_frontend_react.port
    to_port          = local.datahub_frontend_react.port
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    //    cidr_blocks = [
    //      data.aws_vpc.vpc.cidr_block,
    //    ]
  }

  tags = merge(var.tags, {
    "Name" : "DataHub Frontend React Load Balancer"
  })
}

resource "aws_alb_target_group" "datahub_frontend_react" {
  name        = "${var.short_identifier_prefix}datahub-frontend"
  port        = local.datahub_frontend_react.port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    protocol = "HTTP"
    path     = "/admin"
    port     = local.datahub_frontend_react.port
    interval = 60
  }
}

resource "aws_alb" "datahub_frontend_react" {
  name               = "${var.short_identifier_prefix}datahub-frontend"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.datahub_frontend_react.id]
  subnets            = data.aws_subnet.subnets.*.id
}

resource "aws_alb_listener" "datahub_frontend_react" {
  load_balancer_arn = aws_alb.datahub_frontend_react.arn
  port              = local.datahub_frontend_react.port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.datahub_frontend_react.arn
  }
}
