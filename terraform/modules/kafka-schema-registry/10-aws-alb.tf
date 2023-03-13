data "aws_subnet_ids" "subnet_ids" {
  vpc_id = var.vpc_id
}

data "aws_subnet" "subnets" {
  count = length(data.aws_subnet_ids.subnet_ids.ids)
  id    = tolist(data.aws_subnet_ids.subnet_ids.ids)[count.index]
}

resource "aws_security_group" "schema_registry_alb" {
  name                   = "${var.identifier_prefix}schema-registry-alb"
  description            = "Restricts access to the Schema Registry Load Balancer"
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
    description       = "Allow inbound traffic from housing account subnets that the reporting listener lambda is deployed to"
    protocol          = "TCP"
    from_port         = 8081
    to_port           = 8081
    cidr_blocks       = var.housing_intra_account_ingress_cidr
  }

  dynamic ingress {
    for_each = lower(var.environment) != "prod" ? [1] : []
    
    content {
      description     = "Allows inbound traffic from the tester lambda on dev and pre-prod"
      protocol        = "TCP"
      from_port       = 8081
      to_port         = 8081
      security_groups = [var.kafka_tester_lambda_security_group_id]
    }
  }

  tags = merge(var.tags, {
    "Name" : "Schema Registry Load Balancer"
  })
}

resource "aws_alb_target_group" "schema_registry" {
  name        = "${var.identifier_prefix}schema-registry"
  port        = 8081
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}

resource "aws_alb" "schema_registry" {
  name               = "${var.identifier_prefix}schema-registry-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.schema_registry_alb.id]
  subnets            = data.aws_subnet.subnets.*.id
}

resource "aws_alb_listener" "schema_registry_http" {
  load_balancer_arn = aws_alb.schema_registry.arn
  port              = "8081"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.schema_registry.arn
  }
}
