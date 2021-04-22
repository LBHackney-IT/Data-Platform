# AppStream Infrastructure
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
  private_subnets                = var.appstream_tgw_subnets
  single_nat_gateway             = false

  default_security_group_tags = module.tags.values
  tags                        = module.tags.values
}

resource "aws_subnet" "appstream_subnets" {
  for_each = var.appstream_subnets
  provider = aws.appstream

  availability_zone = lookup(each.value, "availability_zone", null)
  cidr_block        = lookup(each.value, "cidr_block", true)
  vpc_id            = module.appstream_vpc.vpc_id

  tags = merge(
    module.tags.values,
    {
      "Name" = each.key
    }
  )
}

resource "aws_route_table" "appstream_route_table" {
  provider = aws.appstream

  vpc_id = module.appstream_vpc.vpc_id

  tags = merge(
    module.tags.values,
    {
      "Name" = format("%s-%s", var.application, var.environment)
    }
  )
}

resource "aws_route_table_association" "route_table_associations" {
  for_each = aws_subnet.appstream_subnets
  provider = aws.appstream

  route_table_id = aws_route_table.appstream_route_table.id
  subnet_id      = each.value.id
}

resource "aws_route" "appstream_hub_tgw_private_routes" {
  for_each = aws_subnet.appstream_subnets
  provider = aws.appstream

  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.appstream_route_table.id
  transit_gateway_id     = data.aws_ec2_transit_gateway.appstream_hub_tgw.id
}
