data "aws_acm_certificate" "datahub" {
  domain = var.ssl_certificate_domain
}

data "aws_subnet" "subnets" {
  count = length(var.vpc_subnet_ids)
  id    = tolist(var.vpc_subnet_ids)[count.index]
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
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Allow inbound HTTPS traffic"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, {
    "Name" : "DataHub Load Balancer"
  })
}

resource "aws_alb_target_group" "datahub" {
  name     = "${var.short_identifier_prefix}datahub"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = var.vpc_id
}

resource "aws_lb_target_group_attachment" "datahub_https" {
  count            = aws_instance.datahub.instance_state == "running" ? 1 : 0
  target_group_arn = aws_alb_target_group.datahub.arn
  target_id        = aws_instance.datahub.id
  port             = 443
}

resource "aws_alb" "datahub" {
  name               = "${var.short_identifier_prefix}datahub-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.datahub_alb.id]
  subnets            = data.aws_subnet.subnets.*.id
  idle_timeout       = 4000

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_alb_listener" "datahub_http" {
  load_balancer_arn = aws_alb.datahub.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_listener" "datahub_https" {
  load_balancer_arn = aws_alb.datahub.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.datahub.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.datahub.arn
  }
}