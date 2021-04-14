# Shared Services Infrastructure
module "ss_primary_vpc" {
  providers = { aws = aws.ss_primary }
  source    = "terraform-aws-modules/vpc/aws"
  version   = "2.64.0"

  azs                                    = var.ss_primary_azs
  cidr                                   = var.ss_primary_cidr
  create_database_internet_gateway_route = var.ss_primary_mgmt_internet_gateway_route
  create_database_subnet_route_table     = var.ss_primary_mgmt_subnet_route_table
  database_subnet_suffix                 = "mgmt"
  database_subnets                       = var.ss_primary_mgmt_subnets
  database_subnet_tags                   = var.ss_primary_mgmt_subnet_tags
  create_redshift_subnet_route_table     = var.ss_primary_tgwattach_subnet_route_table
  redshift_subnet_suffix                 = "tgwattach"
  redshift_subnets                       = var.ss_primary_tgwattach_subnets
  redshift_subnet_tags                   = var.ss_primary_tgwattach_subnet_tags
  create_igw                             = var.ss_primary_create_igw
  enable_dns_hostnames                   = var.ss_primary_enable_dns_hostnames
  enable_dns_support                     = var.ss_primary_enable_dns_support
  enable_nat_gateway                     = var.ss_primary_enable_nat_gateway
  enable_vpn_gateway                     = var.ss_primary_enable_vpn_gateway
  name                                   = format("%s-%s", var.application, var.environment)
  one_nat_gateway_per_az                 = var.ss_primary_one_nat_gateway_per_az
  private_subnets                        = var.ss_primary_private_subnets
  private_subnet_suffix                  = "trust"
  private_subnet_tags                    = var.ss_primary_private_subnet_tags
  public_subnets                         = var.ss_primary_public_subnets
  public_subnet_suffix                   = "untrust"
  public_subnet_tags                     = var.ss_primary_public_subnet_tags
  single_nat_gateway                     = var.ss_primary_single_nat_gateway

  tags = module.tags.values
}

resource "aws_route" "to_spokes" {
  count    = length(module.ss_primary_vpc.private_route_table_ids)
  provider = aws.ss_primary

  route_table_id         = module.ss_primary_vpc.private_route_table_ids[count.index]
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = module.primary_tgw.this_ec2_transit_gateway_id

  timeouts {
    create = "5m"
  }
}
