resource "aws_route" "mosaic_production_dms_route_one" {
  provider = aws.core

  destination_cidr_block    = var.production_api_vpc_cidrs[0]
  route_table_id            = module.core_vpc.vpc_main_route_table_id
  vpc_peering_connection_id = aws_vpc_peering_connection.mosaic_production_peering.id
}

resource "aws_route" "mosaic_production_dms_route_two" {
  provider = aws.core

  destination_cidr_block    = var.production_api_vpc_cidrs[1]
  route_table_id            = module.core_vpc.vpc_main_route_table_id
  vpc_peering_connection_id = aws_vpc_peering_connection.mosaic_production_peering.id
}

resource "aws_route_table_association" "private_subnet_one" {
  provider = aws.core

  route_table_id = module.core_vpc.vpc_main_route_table_id
  subnet_id      = module.core_vpc.private_subnets[0]
}

resource "aws_route_table_association" "private_subnet_two" {
  provider = aws.core

  route_table_id = module.core_vpc.vpc_main_route_table_id
  subnet_id      = module.core_vpc.private_subnets[1]
}
