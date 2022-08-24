# PC Attachment Definitions
locals {
  vpc_attachments = {
    format("%s-hub-attachment", module.core_vpc.name) = {
      vpc_id     = module.core_vpc.vpc_id
      subnet_ids = slice(module.core_vpc.private_subnets, 0, 3)
    }
  }
}

# Hub Transit Gateway

#eu-west-1 - values = ["64513"]
data "aws_ec2_transit_gateway" "hub_tgw" {

  filter {
    name   = "options.amazon-side-asn"
    values = ["64512"]
  }
}

# VPC Attachments
resource "aws_ec2_transit_gateway_vpc_attachment" "hub_tgw_attachment" {
  for_each = local.vpc_attachments

  tags = module.tags.values

  dns_support                                     = lookup(each.value, "dns_support", true) ? "enable" : "disable"
  ipv6_support                                    = lookup(each.value, "ipv6_support", false) ? "enable" : "disable"
  subnet_ids                                      = each.value["subnet_ids"]
  transit_gateway_default_route_table_association = lookup(each.value, "transit_gateway_default_route_table_association", true)
  transit_gateway_default_route_table_propagation = lookup(each.value, "transit_gateway_default_route_table_propagation", true)
  transit_gateway_id                              = lookup(each.value, "tgw_id", data.aws_ec2_transit_gateway.hub_tgw.id)
  vpc_id                                          = each.value["vpc_id"]
}
