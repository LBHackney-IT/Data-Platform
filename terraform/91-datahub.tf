module "datahub" {
  source = "../modules/datahub"

  tags                    = module.tags.values
  operation_name          = "${local.short_identifier_prefix}datahub-frontend-react"
  environment_variables   = local.environment_variables
  ecs_cluster_arn         = aws_ecs_cluster.datahub.arn
  environment             = var.environment
  identifier_prefix       = local.identifier_prefix
  short_identifier_prefix = local.short_identifier_prefix
  alb_id                  = aws_alb.datahub.id
  alb_target_group_arn    = aws_alb_target_group.datahub.arn
  alb_security_group_id   = aws_security_group.datahub_alb.id
  aws_subnet_ids          = data.aws_subnet_ids.network.ids
  vpc_id                  = var.aws_dp_vpc_id
  ecr_repository_url      = aws_ecr_repository.datahub.repository_url
}

resource "aws_ecs_cluster" "datahub" {
  tags = module.tags.values
  name = "${local.identifier_prefix}-datahub"
}

//data "aws_acm_certificate" "datahub" {
//  domain = var.datahub_ssl_certificate_domain
//  statuses = ["ISSUED"]
//}

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
  name        = "${local.short_identifier_prefix}datahub"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = var.aws_dp_vpc_id
  target_type = "ip"
}

resource "aws_alb" "datahub" {
  name               = "${local.short_identifier_prefix}datahub-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.datahub_alb.id]
  subnets            = data.aws_subnet.subnets.*.id
}

//resource "aws_alb_listener" "datahub_http" {
//  load_balancer_arn = aws_alb.datahub.arn
//  port              = "80"
//  protocol          = "HTTP"
//
//  default_action {
//    type = "redirect"
//
//    redirect {
//      port        = "443"
//      protocol    = "HTTPS"
//      status_code = "HTTP_301"
//    }
//  }
//}

resource "aws_alb_listener" "datahub_http" {
  load_balancer_arn = aws_alb.datahub.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.datahub.arn
  }
}

//resource "aws_alb_listener" "datahub_https" {
//  load_balancer_arn = aws_alb.datahub.arn
//  port              = "443"
//  protocol          = "HTTPS"
//  ssl_policy        = "ELBSecurityPolicy-2016-08"
//  certificate_arn   = data.aws_acm_certificate.datahub.arn
//
//  default_action {
//    type             = "forward"
//    target_group_arn = aws_alb_target_group.datahub.arn
//  }
//}

resource "aws_ecr_repository" "datahub" {
  tags = module.tags.values
  name = "${local.identifier_prefix}-datahub"
}

resource "aws_ecr_lifecycle_policy" "repo-policy" {
  repository = aws_ecr_repository.datahub.name

  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep image deployed with tag latest",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["latest"],
        "countType": "imageCountMoreThan",
        "countNumber": 1
      },
      "action": {
        "type": "expire"
      }
    },
    {
      "rulePriority": 2,
      "description": "Keep last 2 any images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 2
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}