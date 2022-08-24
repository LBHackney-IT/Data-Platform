# Core Infrastructure
module "core_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.0.0"

  azs                   = var.transit_gateway_availability_zones
  cidr                  = var.transit_gateway_cidr
  secondary_cidr_blocks = var.secondary_transit_gateway_cidr
  create_igw            = false
  enable_dns_hostnames  = var.core_enable_dns_hostnames
  enable_dns_support    = var.core_enable_dns_support
  enable_nat_gateway    = false
  name                  = local.identifier_prefix
  private_subnets       = var.transit_gateway_private_subnets
  single_nat_gateway    = false
  tags                  = module.tags.values
}

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "3.0.0"

  vpc_id             = module.core_vpc.vpc_id
  security_group_ids = [aws_security_group.service_endpoint.id]

  endpoints = {
    s3 = {
      service      = "s3"
      service_type = "Gateway"
    },
    ssm = {
      service             = "ssm"
      private_dns_enabled = true
      subnet_ids          = slice(module.core_vpc.private_subnets, 0, 3)
      security_group_ids  = [aws_security_group.service_endpoint.id]
    },
    ssmmessages = {
      service             = "ssmmessages"
      private_dns_enabled = true
      subnet_ids          = slice(module.core_vpc.private_subnets, 0, 3)
      security_group_ids  = [aws_security_group.service_endpoint.id]
    },
    lambda = {
      service             = "lambda"
      private_dns_enabled = true
      subnet_ids          = slice(module.core_vpc.private_subnets, 0, 3)
      security_group_ids  = [aws_security_group.service_endpoint.id]
    },
    ecs = {
      service             = "ecs"
      private_dns_enabled = true
      subnet_ids          = slice(module.core_vpc.private_subnets, 0, 3)
      security_group_ids  = [aws_security_group.service_endpoint.id]
    },
    ec2 = {
      service             = "ec2"
      private_dns_enabled = true
      subnet_ids          = slice(module.core_vpc.private_subnets, 0, 3)
      security_group_ids  = [aws_security_group.service_endpoint.id]
    },
    ec2messages = {
      service             = "ec2messages"
      private_dns_enabled = true
      subnet_ids          = slice(module.core_vpc.private_subnets, 0, 3)
      security_group_ids  = [aws_security_group.service_endpoint.id]
    },
    ecr_api = {
      service             = "ecr.api"
      private_dns_enabled = true
      subnet_ids          = slice(module.core_vpc.private_subnets, 0, 3)
      security_group_ids  = [aws_security_group.service_endpoint.id]
    },
    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
      subnet_ids          = slice(module.core_vpc.private_subnets, 0, 3)
      security_group_ids  = [aws_security_group.service_endpoint.id]
    },
    kms = {
      service             = "kms"
      private_dns_enabled = true
      subnet_ids          = slice(module.core_vpc.private_subnets, 0, 3)
      security_group_ids  = [aws_security_group.service_endpoint.id]
    },
    secretsmanager = {
      service             = "secretsmanager"
      private_dns_enabled = true
      subnet_ids          = slice(module.core_vpc.private_subnets, 0, 3)
      security_group_ids  = [aws_security_group.service_endpoint.id]
    },
    sqs = {
      service             = "sqs"
      private_dns_enabled = true
      subnet_ids          = slice(module.core_vpc.private_subnets, 0, 3)
      security_group_ids  = [aws_security_group.service_endpoint.id]
    },
    sns = {
      service             = "sns"
      private_dns_enabled = true
      subnet_ids          = slice(module.core_vpc.private_subnets, 0, 3)
      security_group_ids  = [aws_security_group.service_endpoint.id]
    },
  }

  tags = module.tags.values
}

resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  count           = length(var.transit_gateway_private_subnets)
  vpc_endpoint_id = module.vpc_endpoints.endpoints["s3"].id
  route_table_id  = element(module.core_vpc.private_route_table_ids, count.index)
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

resource "aws_security_group_rule" "ingress_https" {
  security_group_id = aws_security_group.service_endpoint.id
  type              = "ingress"

  cidr_blocks = ["0.0.0.0/0"]
  description = ""

  from_port = "443"
  to_port   = "443"
  protocol  = "TCP"
}

resource "aws_security_group_rule" "ingress_http" {
  security_group_id = aws_security_group.service_endpoint.id
  type              = "ingress"

  cidr_blocks = ["0.0.0.0/0"]
  description = ""

  from_port = "80"
  to_port   = "80"
  protocol  = "TCP"
}

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
