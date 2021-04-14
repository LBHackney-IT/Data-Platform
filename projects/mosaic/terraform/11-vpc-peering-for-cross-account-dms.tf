# Production API VPC details
data "aws_secretsmanager_secret" "production_apis_vpc_id" {
  provider = aws.core

  name = "production_apis_vpc_id"
}

data "aws_secretsmanager_secret_version" "production_apis_vpc_id" {
  provider = aws.core

  secret_id = data.aws_secretsmanager_secret.production_apis_vpc_id.id
}

# Production API Account details
data "aws_secretsmanager_secret" "production_apis_account_id" {
  provider = aws.core

  name = "production_apis_account_id"
}

data "aws_secretsmanager_secret_version" "production_apis_account_id" {
  provider = aws.core

  secret_id = data.aws_secretsmanager_secret.production_apis_account_id.id
}

# Production APIs - Accepter
resource "aws_vpc_peering_connection_accepter" "production_apis_peering" {
  provider = aws.core

  auto_accept               = true
  vpc_peering_connection_id = aws_vpc_peering_connection.mosaic_production_peering.id

  tags = merge(map("Side", "Accepter", "Name", "production-apis-to-mosaic-prod-dms-peer"), module.tags.values)
}

# Mosaic Production - Requester
resource "aws_vpc_peering_connection" "mosaic_production_peering" {
  provider = aws.core

  vpc_id = module.core_vpc.vpc_id

  peer_vpc_id   = data.aws_secretsmanager_secret_version.production_apis_vpc_id.secret_string
  peer_owner_id = data.aws_secretsmanager_secret_version.production_apis_account_id.secret_string
  peer_region   = var.core_region

  auto_accept = false

  tags = merge(map("Side", "Requester", "Name", "production-apis-to-mosaic-prod-dms-peer"), module.tags.values)
}
