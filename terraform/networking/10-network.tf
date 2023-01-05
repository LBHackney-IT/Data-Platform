# Core Infrastructure
module "core_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.70.0"

  azs                  = var.transit_gateway_availability_zones
  cidr                 = var.transit_gateway_cidr
  create_igw           = false
  enable_dns_hostnames = var.core_enable_dns_hostnames
  enable_dns_support   = var.core_enable_dns_support
  enable_nat_gateway   = false
  name                 = local.identifier_prefix
  private_subnets      = var.transit_gateway_private_subnets
  single_nat_gateway   = false

  enable_s3_endpoint = true

  enable_secretsmanager_endpoint              = true
  secretsmanager_endpoint_security_group_ids  = [aws_security_group.service_endpoint.id]
  secretsmanager_endpoint_private_dns_enabled = true

  enable_ssm_endpoint              = true
  ssm_endpoint_security_group_ids  = [aws_security_group.service_endpoint.id]
  ssm_endpoint_private_dns_enabled = true

  enable_ssmmessages_endpoint              = true
  ssmmessages_endpoint_security_group_ids  = [aws_security_group.service_endpoint.id]
  ssmmessages_endpoint_private_dns_enabled = true

  enable_ec2messages_endpoint              = true
  ec2messages_endpoint_security_group_ids  = [aws_security_group.service_endpoint.id]
  ec2messages_endpoint_private_dns_enabled = true

  enable_ecr_api_endpoint              = true
  ecr_api_endpoint_security_group_ids  = [aws_security_group.service_endpoint.id]
  ecr_api_endpoint_private_dns_enabled = true

  enable_ecr_dkr_endpoint              = true
  ecr_dkr_endpoint_security_group_ids  = [aws_security_group.service_endpoint.id]
  ecr_dkr_endpoint_private_dns_enabled = true

  enable_kms_endpoint              = true
  kms_endpoint_security_group_ids  = [aws_security_group.service_endpoint.id]
  kms_endpoint_private_dns_enabled = true

  enable_sqs_endpoint              = true
  sqs_endpoint_security_group_ids  = [aws_security_group.service_endpoint.id]
  sqs_endpoint_private_dns_enabled = true

  enable_lambda_endpoint              = true
  lambda_endpoint_security_group_ids  = [aws_security_group.service_endpoint.id]
  lambda_endpoint_private_dns_enabled = true

  enable_sns_endpoint              = true
  sns_endpoint_security_group_ids  = [aws_security_group.service_endpoint.id]
  sns_endpoint_private_dns_enabled = true

  enable_ecs_endpoint                    = true
  ecs_endpoint_security_group_ids        = [aws_security_group.service_endpoint.id]
  ecs_agent_endpoint_private_dns_enabled = true

  tags = module.tags.values
}

resource "aws_ssm_parameter" "vpc_id" {
  name  = "/${local.identifier_prefix}/vpc/vpc_id"
  type  = "String"
  value = module.core_vpc.vpc_id
  tags = merge(module.tags.values, {
    "Name" : "VPC ID"
  })
}

resource "aws_security_group" "service_endpoint" {
  name                   = "${local.identifier_prefix}-service-endpoint"
  description            = "Group Description"
  vpc_id                 = module.core_vpc.vpc_id
  revoke_rules_on_delete = true

  tags = merge(module.tags.values, {
    "Name" : "Service Endpoint"
  })
}

# resource "aws_security_group_rule" "ingress_https" {
#   security_group_id = aws_security_group.service_endpoint.id
#   type              = "ingress"

#   cidr_blocks = ["0.0.0.0/0"]
#   description = ""

#   from_port = "443"
#   to_port   = "443"
#   protocol  = "TCP"
# }

resource "aws_security_group_rule" "ingress_http" {
  security_group_id = aws_security_group.service_endpoint.id
  type              = "ingress"

  cidr_blocks = ["0.0.0.0/0"]
  description = ""

  from_port = "80"
  to_port   = "80"
  protocol  = "TCP"
}
# trigger workflow for a test plan
# Resource -  VPC Routes
resource "aws_route" "hub_tgw_routes" {
  count = length(module.core_vpc.private_route_table_ids)

  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = module.core_vpc.private_route_table_ids[count.index]
  transit_gateway_id     = data.aws_ec2_transit_gateway.hub_tgw.id
}

# ElasticSearch service linked role
resource "aws_iam_service_linked_role" "elastic_search" {
  tags             = module.tags.values
  aws_service_name = "es.amazonaws.com"
}
