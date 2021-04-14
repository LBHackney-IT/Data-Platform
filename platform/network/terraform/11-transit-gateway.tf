# Shared Services Infrastructure
data "aws_region" "ss_secondary" {
  provider = aws.ss_secondary
}

# Shared Services Infrastructure - Transit Gateways
module "primary_tgw" {
  providers = { aws = aws.ss_primary }
  source    = "terraform-aws-modules/transit-gateway/aws"
  version   = "1.4.0"

  amazon_side_asn                        = var.ss_primary_amazon_side_asn
  create_tgw                             = var.ss_primary_create_tgw
  description                            = "Shared Services Transit Gateway."
  enable_auto_accept_shared_attachments  = var.ss_primary_enable_auto_accept_shared_attachments
  enable_default_route_table_association = false
  enable_default_route_table_propagation = false
  name                                   = format("%s-tgw-%s", var.application, var.environment)
  ram_name                               = format("%s-tgw-%s", var.application, var.environment)
  ram_principals                         = var.ss_primary_ram_principals
  share_tgw                              = var.ss_primary_share_tgw

  tags                 = module.tags.values
  tgw_route_table_tags = merge({ "Name" = format("rtb-%s-security", var.environment) }, module.tags.values)
}

module "secondary_tgw" {
  providers = { aws = aws.ss_secondary }
  source    = "terraform-aws-modules/transit-gateway/aws"
  version   = "1.4.0"

  amazon_side_asn                        = var.ss_secondary_amazon_side_asn
  create_tgw                             = var.ss_secondary_create_tgw
  description                            = "Shared Services Transit Gateway."
  enable_auto_accept_shared_attachments  = var.ss_secondary_enable_auto_accept_shared_attachments
  enable_default_route_table_association = false
  enable_default_route_table_propagation = false
  name                                   = format("%s-tgw-%s", var.application, var.environment)
  ram_name                               = format("%s-tgw-%s", var.application, var.environment)
  ram_principals                         = var.ss_secondary_ram_principals
  share_tgw                              = var.ss_secondary_share_tgw

  tags                 = module.tags.values
  tgw_route_table_tags = merge({ "Name" = format("rtb-%s-security", var.environment) }, module.tags.values)
}

# Shared Services Infrastructure - Transit Gateway Peering
resource "aws_ec2_transit_gateway_peering_attachment" "tgw_peer" {
  provider = aws.ss_primary

  peer_account_id         = module.secondary_tgw.this_ec2_transit_gateway_owner_id
  peer_region             = data.aws_region.ss_secondary.name
  peer_transit_gateway_id = module.secondary_tgw.this_ec2_transit_gateway_id
  transit_gateway_id      = module.primary_tgw.this_ec2_transit_gateway_id

  tags = merge(
    {
      "Name" = format("%s-tgw-%s-peering", var.application, var.environment)
    },
    module.tags.values,
  )
}

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "tgw_peer_accepter" {
  provider = aws.ss_secondary

  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.tgw_peer.id

  tags = merge(
    {
      "Name" = format("%s-tgw-%s-peering", var.application, var.environment)
    },
    module.tags.values,
  )
}

resource "aws_ec2_transit_gateway_route_table_association" "primary_transit_gateway_route_table_association_peer" {
  depends_on = [aws_ec2_transit_gateway_peering_attachment_accepter.tgw_peer_accepter]
  provider   = aws.ss_primary

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.tgw_peer.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.primary_transit_gateway_route_table_spoke.id
}

resource "aws_ec2_transit_gateway_route" "primary_tgw_internet_route_peer" {
  depends_on = [aws_ec2_transit_gateway_peering_attachment_accepter.tgw_peer_accepter]
  for_each   = var.ss_secondary_routes_tgw
  provider   = aws.ss_primary

  destination_cidr_block         = each.value
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.tgw_peer.id
  transit_gateway_route_table_id = module.primary_tgw.this_ec2_transit_gateway_route_table_id
}

# Primary & Secondary Locals

locals {
  primary_remote_vpc_attachments   = flatten(jsondecode(data.external.primary_remote_vpc_attachments.result.as_string))
  secondary_remote_vpc_attachments = flatten(jsondecode(data.external.secondary_remote_vpc_attachments.result.as_string))
}

# Primary
resource "aws_ec2_transit_gateway_vpc_attachment" "primary_transit_gateway_vpc_attachment_security" {
  provider = aws.ss_primary

  subnet_ids                                      = module.ss_primary_vpc.redshift_subnets
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  transit_gateway_id                              = module.primary_tgw.this_ec2_transit_gateway_id
  vpc_id                                          = module.ss_primary_vpc.vpc_id

  tags = merge(
    {
      "Name" = format("%s-tgw-%s-security", var.application, var.environment)
    },
    module.tags.values,
  )
}

resource "aws_ec2_transit_gateway_route_table" "primary_transit_gateway_route_table_spoke" {
  provider = aws.ss_primary

  transit_gateway_id = module.primary_tgw.this_ec2_transit_gateway_id

  tags = merge(
    {
      "Name" = format("rtb-%s-spoke", var.environment)
    },
    module.tags.values,
  )
}

resource "aws_ec2_transit_gateway_route_table_association" "primary_transit_gateway_route_table_association_spoke" {
  provider = aws.ss_primary

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.primary_transit_gateway_vpc_attachment_security.id
  transit_gateway_route_table_id = module.primary_tgw.this_ec2_transit_gateway_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "primary_tgw_propagation_spoke" {
  provider = aws.ss_primary

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.primary_transit_gateway_vpc_attachment_security.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.primary_transit_gateway_route_table_spoke.id
}


resource "aws_ec2_transit_gateway_route" "primary_tgw_internet_route_spoke" {
  provider = aws.ss_primary

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.primary_transit_gateway_vpc_attachment_security.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.primary_transit_gateway_route_table_spoke.id
}

data "external" "primary_remote_vpc_attachments" {
  program = ["bash", "${path.root}/automation/vpc_attachments_query.sh"]
  query = {
    aws_deploy_account       = var.aws_deploy_account
    aws_deploy_iam_role_name = var.aws_deploy_iam_role_name
    aws_deploy_region        = var.ss_primary_region
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "primary_transit_gateway_route_table_association_security" {
  for_each = { for attachment in local.primary_remote_vpc_attachments : attachment.TransitGatewayAttachmentId => attachment }
  provider = aws.ss_primary

  transit_gateway_attachment_id  = each.value.TransitGatewayAttachmentId
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.primary_transit_gateway_route_table_spoke.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "primary_tgw_propagation_security" {
  for_each = { for attachment in local.primary_remote_vpc_attachments : attachment.TransitGatewayAttachmentId => attachment }
  provider = aws.ss_primary

  transit_gateway_attachment_id  = each.value.TransitGatewayAttachmentId
  transit_gateway_route_table_id = module.primary_tgw.this_ec2_transit_gateway_route_table_id
}

# Secondary
resource "aws_ec2_transit_gateway_route_table" "secondary_transit_gateway_route_table_spoke" {
  provider = aws.ss_secondary

  transit_gateway_id = module.secondary_tgw.this_ec2_transit_gateway_id

  tags = merge(
    {
      "Name" = format("rtb-%s-spoke", var.environment)
    },
    module.tags.values,
  )
}

resource "aws_ec2_transit_gateway_route_table_association" "secondary_transit_gateway_route_table_association_spoke" {
  provider = aws.ss_secondary

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment_accepter.tgw_peer_accepter.id
  transit_gateway_route_table_id = module.secondary_tgw.this_ec2_transit_gateway_route_table_id
}

resource "aws_ec2_transit_gateway_route" "secondary_tgw_internet_route_spoke" {
  provider = aws.ss_secondary

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment_accepter.tgw_peer_accepter.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.secondary_transit_gateway_route_table_spoke.id
}

data "external" "secondary_remote_vpc_attachments" {
  program = ["bash", "${path.root}/automation/vpc_attachments_query.sh"]
  query = {
    aws_deploy_account       = var.aws_deploy_account
    aws_deploy_iam_role_name = var.aws_deploy_iam_role_name
    aws_deploy_region        = var.ss_secondary_region
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "secondary_transit_gateway_route_table_association_security" {
  for_each = { for attachment in local.secondary_remote_vpc_attachments : attachment.TransitGatewayAttachmentId => attachment }
  provider = aws.ss_secondary

  transit_gateway_attachment_id  = each.value.TransitGatewayAttachmentId
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.secondary_transit_gateway_route_table_spoke.id
}
