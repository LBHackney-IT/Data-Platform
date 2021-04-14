resource "aws_route" "mosaic_production_dms_route" {
  provider = aws.core

  destination_cidr_block    = var.production_api_vpc_cidr
  route_table_id            = module.core_vpc.vpc_main_route_table_id
  vpc_peering_connection_id = aws_vpc_peering_connection.mosaic_production_peering.id
}
