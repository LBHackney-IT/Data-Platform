locals {
  appstream_routes = {
    for pair in setproduct(module.appstream_vpc.private_route_table_ids, var.core_private_subnets) : "${pair[0]} ${pair[1]}" => {
      route_table_id = pair[0]
      subnet_cidr    = pair[1]
    }
  }
  core_routes = {
    for pair in setproduct(module.core_vpc.private_route_table_ids, var.appstream_private_subnets) : "${pair[0]} ${pair[1]}" => {
      route_table_id = pair[0]
      subnet_cidr    = pair[1]
    }
  }
}

resource "aws_route" "appstream_route" {
  for_each = local.appstream_routes
  provider = aws.appstream

  destination_cidr_block    = each.value.subnet_cidr
  route_table_id            = each.value.route_table_id
  vpc_peering_connection_id = aws_vpc_peering_connection.core_peering.id
}

resource "aws_route" "core_route" {
  for_each = local.core_routes
  provider = aws.core

  destination_cidr_block    = each.value.subnet_cidr
  route_table_id            = each.value.route_table_id
  vpc_peering_connection_id = aws_vpc_peering_connection.core_peering.id
}
