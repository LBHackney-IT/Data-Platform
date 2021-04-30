# Core Infrastructure
module "core_vpc" {
  source    = "terraform-aws-modules/vpc/aws"
  version   = "2.64.0"

  azs                  = var.core_azs
  cidr                 = var.core_cidr
  create_igw           = false
  enable_dns_hostnames = var.core_enable_dns_hostnames
  enable_dns_support   = var.core_enable_dns_support
  enable_nat_gateway   = false
  name                 = format("%s-%s", var.application, var.environment)
  private_subnets      = var.core_private_subnets
  single_nat_gateway   = false

  tags = module.tags.values
}

# Resource -  VPC Routes
resource "aws_route" "hub_tgw_routes" {
  count    = length(module.core_vpc.private_route_table_ids)

  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = module.core_vpc.private_route_table_ids[count.index]
  transit_gateway_id     = data.aws_ec2_transit_gateway.hub_tgw.id
}
