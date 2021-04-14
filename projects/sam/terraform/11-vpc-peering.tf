# AppStream Infrastructure - Accepter
resource "aws_vpc_peering_connection_accepter" "appstream_peering" {
  provider = aws.appstream

  auto_accept               = true
  vpc_peering_connection_id = aws_vpc_peering_connection.core_peering.id

  tags = module.tags.values
}

# Core Infrastructure - Requester
resource "aws_vpc_peering_connection" "core_peering" {
  provider = aws.core

  peer_region = var.appstream_region
  peer_vpc_id = module.appstream_vpc.vpc_id
  vpc_id      = module.core_vpc.vpc_id

  tags = module.tags.values
}

