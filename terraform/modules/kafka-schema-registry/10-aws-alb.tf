data "aws_subnets" "subnet_ids" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

data "aws_subnet" "subnets" {
  count = length(data.aws_subnets.subnet_ids.ids)
  id    = tolist(data.aws_subnets.subnet_ids.ids)[count.index]
}

resource "aws_security_group" "schema_registry_alb" {
  name                   = "${var.identifier_prefix}schema-registry-alb"
  description            = "Restricts access to the Schema Registry Load Balancer"
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true

  tags = merge(var.tags, {
    "Name" : "Schema Registry Load Balancer"
  })
}

resource "aws_security_group_rule" "datahub_actions_ingress" {
  description              = "Allows inbound traffic from Datahub Actions"
  type                     = "ingress"
  from_port                = 8081
  to_port                  = 8081
  protocol                 = "TCP"
  source_security_group_id = var.datahub_actions_security_group_id
  security_group_id        = aws_security_group.schema_registry_alb.id
}

resource "aws_security_group_rule" "datahub_gms_ingress" {
  description              = "Allows inbound traffic from Datahub Generalized Metadata Service (GMS)"
  type                     = "ingress"
  from_port                = 8081
  to_port                  = 8081
  protocol                 = "TCP"
  source_security_group_id = var.datahub_gms_security_group_id
  security_group_id        = aws_security_group.schema_registry_alb.id
}

resource "aws_security_group_rule" "datahub_mae_ingress" {
  description              = "Allows inbound traffic from Datahub Metadata Audit Event (MAE)"
  type                     = "ingress"
  from_port                = 8081
  to_port                  = 8081
  protocol                 = "TCP"
  source_security_group_id = var.datahub_mae_consumer_security_group_id
  security_group_id        = aws_security_group.schema_registry_alb.id
}

resource "aws_security_group_rule" "datahub_mce_ingress" {
  description              = "Allows inbound traffic from Datahub Metadata Change Event (MCE)"
  type                     = "ingress"
  from_port                = 8081
  to_port                  = 8081
  protocol                 = "TCP"
  source_security_group_id = var.datahub_mce_consumer_security_group_id
  security_group_id        = aws_security_group.schema_registry_alb.id
}

resource "aws_security_group_rule" "housing_listener_ingress" {
  description       = "Allow inbound traffic from housing account subnets that the reporting listener lambda is deployed to"
  type              = "ingress"
  from_port         = 8081
  to_port           = 8081
  protocol          = "TCP"
  cidr_blocks       = var.housing_intra_account_ingress_cidr
  security_group_id = aws_security_group.schema_registry_alb.id
}

resource "aws_security_group_rule" "allow_all_outbound_traffic" {
  description       = "Allow all outbound traffic"
  security_group_id = aws_security_group.schema_registry_alb.id
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "kafka_tester_ingress" {
  count = lower(var.environment) != "prod" ? 1 : 0

  description              = "Allows inbound traffic from the tester lambda on dev and pre-prod"
  type                     = "ingress"
  from_port                = 8081
  to_port                  = 8081
  protocol                 = "TCP"
  source_security_group_id = var.kafka_tester_lambda_security_group_id
  security_group_id        = aws_security_group.schema_registry_alb.id
}

resource "aws_security_group_rule" "allow_kafka_ingress" {
  description              = "Allows inbound traffic from Kafka"
  type                     = "ingress"
  from_port                = 8081
  to_port                  = 8081
  protocol                 = "TCP"
  source_security_group_id = var.kafka_security_group_id
  security_group_id        = aws_security_group.schema_registry_alb.id
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
