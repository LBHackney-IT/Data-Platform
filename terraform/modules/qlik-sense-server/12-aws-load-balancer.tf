data "aws_acm_certificate" "qlik_sense" {
  domain = var.ssl_certificate_domain
}

data "aws_subnet_ids" "subnet_ids" {
  vpc_id = var.vpc_id
}

data "aws_subnet" "subnets" {
  count = length(data.aws_subnet_ids.subnet_ids.ids)
  id    = tolist(data.aws_subnet_ids.subnet_ids.ids)[count.index]
}

resource "aws_security_group" "qlik_sense_alb" {
  name                   = "${var.short_identifier_prefix}qlik-sense-alb"
  description            = "Restricts access to the Qlik Sense Application Load Balancer"
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
    "Name" : "Qlik Sense Load Balancer"
  })
}

resource "aws_alb_target_group" "qlik-sense" {
  name     = "${var.short_identifier_prefix}qlik-sense"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = var.vpc_id

  health_check {
    protocol = "HTTPS"
    path     = "/hub/"
    matcher  = "302"
  }

  stickiness {
    type = "lb_cookie"
  }
}

resource "aws_lb_target_group_attachment" "qlik-sense-tg-attachment" {
  count            = data.aws_instance.qlik-sense-aws-instance.instance_state == "running" ? 1 : 0
  target_group_arn = aws_alb_target_group.qlik-sense.arn
  target_id        = data.aws_instance.qlik-sense-aws-instance.id
  port             = 443
}

resource "aws_alb" "qlik_sense" {
  name               = "${var.short_identifier_prefix}qlik-sense-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.qlik_sense_alb.id]
  subnets            = data.aws_subnet.subnets.*.id
  idle_timeout       = 4000

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_alb_listener" "qlik_sense_http" {
  load_balancer_arn = aws_alb.qlik_sense.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
      path        = "/saml/hub"
    }
  }
}

resource "aws_alb_listener" "qlik_sense_https" {
  load_balancer_arn = aws_alb.qlik_sense.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.qlik_sense.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.qlik-sense.arn
  }
}