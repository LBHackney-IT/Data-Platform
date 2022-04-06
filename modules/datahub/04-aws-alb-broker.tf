resource "aws_security_group" "broker" {
  name                   = "${var.short_identifier_prefix}broker-alb"
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
    from_port        = local.broker.port
    to_port          = local.broker.port
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Allow inbound HTTP traffic"
    from_port        = 9092
    to_port          = 9092
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, {
    "Name" : "Broker Load Balancer"
  })
}

resource "aws_alb_target_group" "broker" {
  name        = "${var.short_identifier_prefix}broker"
  port        = local.broker.port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}

resource "aws_alb" "broker" {
  name               = "${var.short_identifier_prefix}broker"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.broker.id]
  subnets            = data.aws_subnet.subnets.*.id
}

resource "aws_alb_listener" "broker" {
  load_balancer_arn = aws_alb.broker.arn
  port              = local.broker.port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.broker.arn
  }
}
