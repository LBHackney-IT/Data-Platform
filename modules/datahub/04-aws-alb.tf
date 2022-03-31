data "aws_subnet_ids" "subnet_ids" {
  vpc_id = var.vpc_id
}

data "aws_subnet" "subnets" {
  count = length(data.aws_subnet_ids.subnet_ids.ids)
  id    = tolist(data.aws_subnet_ids.subnet_ids.ids)[count.index]
}

resource "aws_security_group" "datahub_alb" {
  name                   = "${var.short_identifier_prefix}datahub-alb"
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
    from_port        = local.datahub_frontend_react.port
    to_port          = local.datahub_frontend_react.port
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, {
    "Name" : "DataHub Load Balancer"
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
  name               = "${var.short_identifier_prefix}datahub-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.datahub_alb.id]
  subnets            = data.aws_subnet.subnets.*.id
}

resource "aws_alb_listener" "datahub_http" {
  load_balancer_arn = aws_alb.datahub.arn
  port              = local.datahub_frontend_react.port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.datahub.arn
  }
}
