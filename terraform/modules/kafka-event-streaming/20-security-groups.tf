data "aws_secretsmanager_secret" "kafka_intra_account_ingress_rules" {
    name = "${var.identifier_prefix}-manually-managed-value-kafka-intra-account-ingress-rules"
}

data "aws_secretsmanager_secret_version" "kafka_intra_account_ingress_rules"{
    secret_id = data.aws_secretsmanager_secret.kafka_intra_account_ingress_rules.id
}

locals {
  kafka_intra_account_ingress_rules = jsondecode(data.aws_secretsmanager_secret_version.kafka_intra_account_ingress_rules.secret_string)
}

resource "aws_security_group" "kafka" {
  name        = "${var.short_identifier_prefix}kafka"
  tags        = var.tags
  vpc_id      = var.vpc_id
  description = "Specifies rules for traffic to the kafka cluster"
}
  
resource "aws_security_group_rule" "allow_inbound_to_zookeeper" {
  description       = "Allows inbound traffic on ZooKeeper port"
  type              = "ingress"
  from_port         = 2182
  to_port           = 2182
  protocol          = "TCP"
  security_group_id = aws_security_group.kafka.id
  self              = true
}

resource "aws_security_group_rule" "datahub_actions_ingress" {
  description               = "Allows inbound traffic from Datahub Actions"
  type                      = "ingress"
  from_port                 = 9094
  to_port                   = 9094
  protocol                  = "TCP"
  source_security_group_id  = var.datahub_actions_security_group_id
  security_group_id         = aws_security_group.kafka.id
}

resource "aws_security_group_rule" "datahub_gms_ingress" {
  description               = "Allows inbound traffic from Datahub Generalized Metadata Service (GMS)"
  type                      = "ingress"
  from_port                 = 9094
  to_port                   = 9094
  protocol                  = "TCP"
  source_security_group_id  = var.datahub_gms_security_group_id
  security_group_id         =  aws_security_group.kafka.id
}

resource "aws_security_group_rule" "datahub_mae_ingress" {
  description               = "Allows inbound traffic from Datahub Metadata Audit Event (MAE)"
  type                      = "ingress"
  from_port                 = 9094
  to_port                   = 9094
  protocol                  = "TCP"
  source_security_group_id  = var.datahub_mae_consumer_security_group_id
  security_group_id         = aws_security_group.kafka.id
}

resource "aws_security_group_rule" "datahub_mce_ingress" {
  description               = "Allows inbound traffic from Datahub Metadata Change Event (MCE)"
  type                      = "ingress"
  from_port                 = 9094
  to_port                   = 9094
  protocol                  = "TCP"
  source_security_group_id  = var.datahub_mce_consumer_security_group_id
  security_group_id         =  aws_security_group.kafka.id
}

resource "aws_security_group_rule" "allow_outbound_traffic_within_sg" {
  description              = "Allow all outbound traffic within the security group"
  security_group_id        = aws_security_group.kafka.id
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  type                     = "egress"
  source_security_group_id = aws_security_group.kafka.id
}

resource "aws_security_group_rule" "allow_inbound_traffic_within_sg" {
  description              = "Allow all inbound traffic within the security group"
  security_group_id        = aws_security_group.kafka.id
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  type                     = "ingress"
  source_security_group_id = aws_security_group.kafka.id
}

resource "aws_security_group_rule" "allow_outbound_traffic_to_s3" {
  description       = "Allow outbound traffic to port 443 to allow writing to S3"
  security_group_id = aws_security_group.kafka.id
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "allow_outbound_traffic_to_schema_registry" {
  description              = "Allow outbound traffic to schema registry load balancer"
  security_group_id        = aws_security_group.kafka.id
  protocol                 = "TCP"
  from_port                = 8081
  to_port                  = 8081
  type                     = "egress"
  source_security_group_id = module.schema_registry.load_balancer_security_group_id
}

resource "aws_security_group_rule" "allow_inboud_traffic_from_housing_account" {
  description       = "Allow inbound traffic from housing account subnets that the reporting listener lambda is deployed to"
  security_group_id = aws_security_group.kafka.id
  protocol          = "TCP"
  from_port         = 9094
  to_port           = 9094
  type              = "ingress"
  cidr_blocks       = local.kafka_intra_account_ingress_rules["cidr_blocks"]
}

resource "aws_security_group_rule" "allow_inbound_traffic_from_tester_lambda" {
  count                     = lower(var.environment) != "prod" ? 1: 0 
  description               = "Allows inbound traffic from the tester lambda on dev and pre-prod"
  security_group_id         = aws_security_group.kafka.id
  protocol                  = "TCP"
  from_port                 = 9094
  to_port                   = 9094
  type                      = "ingress"
  source_security_group_id  = var.kafka_tester_lambda_security_group_id
}

resource "aws_security_group_rule" "allow_inbound_traffic_from_schema_registry_service" {
  description               = "Allows inbound traffic from schema registry service"
  security_group_id         = aws_security_group.kafka.id
  protocol                  = "TCP"
  from_port                 = 9094
  to_port                   = 9094
  type                      = "ingress"
  source_security_group_id = module.schema_registry.schema_registry_security_group_id
}
