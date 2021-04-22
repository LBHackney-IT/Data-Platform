resource "aws_route" "vpc_peer_private_subnet_table_one" {
  provider = aws.core

  count = length(var.production_api_vpc_cidrs)

  route_table_id            = module.core_vpc.private_route_table_ids[0]
  destination_cidr_block    = element(var.production_api_vpc_cidrs, count.index)
  vpc_peering_connection_id = aws_vpc_peering_connection.mosaic_production_peering.id
}

resource "aws_route" "vpc_peer_private_subnet_table_two" {
  provider = aws.core

  count = length(var.production_api_vpc_cidrs)

  route_table_id            = module.core_vpc.private_route_table_ids[1]
  destination_cidr_block    = element(var.production_api_vpc_cidrs, count.index)
  vpc_peering_connection_id = aws_vpc_peering_connection.mosaic_production_peering.id
}
