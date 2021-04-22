# # AppStream Infrastructure
module "appstream_vpc" {
  providers = { aws = aws.appstream }
  source    = "terraform-aws-modules/vpc/aws"
  version   = "2.64.0"

  azs                            = var.appstream_azs
  cidr                           = var.appstream_cidr
  create_igw                     = false
  default_security_group_egress  = var.appstream_security_group_egress
  default_security_group_ingress = var.appstream_security_group_ingress
  default_security_group_name    = format("%s-%s-appstream-vpc-sg", var.application, var.environment)
  enable_dns_hostnames           = var.appstream_enable_dns_hostnames
  enable_dns_support             = var.appstream_enable_dns_support
  enable_nat_gateway             = false
  manage_default_security_group  = true
  name                           = format("%s-%s", var.application, var.environment)
  private_subnets                = var.appstream_private_subnets
  public_subnets                 = var.appstream_public_subnets
  single_nat_gateway             = false

  default_security_group_tags = module.tags.values
  tags                        = module.tags.values
}

# Resource -  VPC Routes
resource "aws_route" "appstream_hub_tgw_private_routes" {
  count    = length(module.appstream_vpc.private_route_table_ids)
  provider = aws.appstream

  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = module.appstream_vpc.private_route_table_ids[count.index]
  transit_gateway_id     = data.aws_ec2_transit_gateway.appstream_hub_tgw.id
}

resource "aws_route" "appstream_hub_tgw_public_routes" {
  count    = length(module.appstream_vpc.public_route_table_ids)
  provider = aws.appstream

  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = module.appstream_vpc.public_route_table_ids[count.index]
  transit_gateway_id     = data.aws_ec2_transit_gateway.appstream_hub_tgw.id
}

# Core Infrastructure
module "core_vpc" {
  providers = { aws = aws.core }
  source    = "terraform-aws-modules/vpc/aws"
  version   = "2.64.0"

  azs                            = var.core_azs
  cidr                           = var.core_cidr
  create_igw                     = false
  default_security_group_egress  = var.core_security_group_egress
  default_security_group_ingress = var.core_security_group_ingress
  default_security_group_name    = format("%s-%s-core-vpc-sg", var.application, var.environment)
  enable_dns_hostnames           = var.core_enable_dns_hostnames
  enable_dns_support             = var.core_enable_dns_support
  enable_nat_gateway             = false
  manage_default_security_group  = true
  name                           = format("%s-%s", var.application, var.environment)
  private_subnets                = var.core_private_subnets
  public_subnets                 = var.core_public_subnets
  single_nat_gateway             = false

  default_security_group_tags = module.tags.values
  tags                        = module.tags.values
}

# Resource -  VPC Routes
resource "aws_route" "core_hub_tgw_private_routes" {
  count    = length(module.core_vpc.private_route_table_ids)
  provider = aws.core

  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = module.core_vpc.private_route_table_ids[count.index]
  transit_gateway_id     = data.aws_ec2_transit_gateway.core_hub_tgw.id
}

resource "aws_route" "core_hub_tgw_public_routes" {
  count    = length(module.core_vpc.private_route_table_ids)
  provider = aws.core

  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = module.core_vpc.public_route_table_ids[count.index]
  transit_gateway_id     = data.aws_ec2_transit_gateway.core_hub_tgw.id
}
