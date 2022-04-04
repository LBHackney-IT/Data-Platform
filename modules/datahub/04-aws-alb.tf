resource "aws_security_group" "datahub" {
  name                   = "${var.short_identifier_prefix}datahub"
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
    description      = "Allow inbound HTTP traffic"
    from_port        = local.datahub_frontend_react.port
    to_port          = local.datahub_frontend_react.port
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, {
    "Name" : "DataHub Frontend React Load Balancer"
  })
}

resource "aws_alb_target_group" "datahub" {
  name        = "${var.short_identifier_prefix}datahub"
  port        = local.datahub_frontend_react.port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}

resource "aws_alb" "datahub" {
  name               = "${var.short_identifier_prefix}datahub"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.datahub.id]
  subnets            = data.aws_subnet.subnets.*.id
}

resource "aws_alb_listener" "datahub" {
  load_balancer_arn = aws_alb.datahub.arn
  port              = local.datahub_frontend_react.port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.datahub.arn
  }
}
