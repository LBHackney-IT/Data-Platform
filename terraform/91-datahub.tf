module "datahub" {
  source = "../modules/aws-ecs-fargate-service"

  tags                          = module.tags.values
  operation_name                = "${local.short_identifier_prefix}datahub"
  environment_variables         = local.environment_variables
  ecs_task_role_policy_document = data.aws_iam_policy_document.task_role.json
  aws_subnet_ids                = data.aws_subnet_ids.network.ids
  ecs_cluster_arn               = aws_ecs_cluster.datahub.arn
  environment                   = var.environment
  identifier_prefix             = local.identifier_prefix
  short_identifier_prefix       = local.short_identifier_prefix
  alb_id                        = aws_alb.datahub.id
  alb_target_group_arn          = aws_alb_target_group.datahub.arn
  vpc_subnet_ids                = local.subnet_ids_list
}

resource "aws_ecs_cluster" "datahub" {
  tags = module.tags.values
  name = "${local.identifier_prefix}-datahub"
}

data "aws_acm_certificate" "datahub" {
  domain = var.datahub_ssl_certificate_domain
}

data "aws_subnet" "subnets" {
  count = length(local.subnet_ids_list)
  id    = tolist(local.subnet_ids_list)[count.index]
}

resource "aws_security_group" "datahub_alb" {
  name                   = "${local.short_identifier_prefix}datahub-alb"
  description            = "Restricts access to the DataHub Application Load Balancer"
  vpc_id                 = var.aws_dp_vpc_id
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

  tags = merge(module.tags.values, {
    "Name" : "DataHub Load Balancer"
  })
}

resource "aws_alb_target_group" "datahub" {
  name     = "${local.short_identifier_prefix}datahub"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = var.aws_dp_vpc_id
}

resource "aws_alb" "datahub" {
  name               = "${local.short_identifier_prefix}datahub-alb"
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
    type = "ip"
  }
}