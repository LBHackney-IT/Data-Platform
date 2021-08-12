//resource "aws_vpc_peering_connection" "data_platform_staging_vpc" {
//  peer_owner_id = "484466746276"  // Defaults to account ID the AWS Provider is currently connected to
//  vpc_id = "vpc-076a7c128ec4a2cf9" // testing with dev account first. should be {module.core_vpc.vp}
//  peer_vpc_id = var.aws_staging_api_vpc_id
//
//  tags = {
//    Name = "VPC Peering between Data Platform Staging and Staging APIs accounts"
//  }
//}
//
//resource "aws_vpc_peering_connection_accepter" "staging_api_vpc" {
//  provider = aws.aws_api_account
//  vpc_peering_connection_id = aws_vpc_peering_connection.data_platform_staging_vpc.id
//
//  tags = {
//    Name = "VPC peer to staging api account"
//  }
//  accepter {
//    allow_remote_vpc_dns_resolution = var.accepter_allow_remote_vpc_dns_resolution
//  }
//}
//
//resource "aws_route" "data_platform_staging_vpc_route" {
//  count = length(var.dataplatform_route_table_ids)
//  route_table_id            = var.dataplatform_route_table_ids[count.index]
//  destination_cidr_block    = var.staging_api_destination_cidr_block
//  vpc_peering_connection_id = aws_vpc_peering_connection.data_platform_staging_vpc.id
//}
//
//resource "aws_route" "staging_api_vpc_route" {
//  provider = aws.aws_api_account
//  count = length(var.staging_api_route_table_ids)
//
//  route_table_id            = var.staging_api_route_table_ids[count.index]
//  destination_cidr_block    = "10.120.30.0/24" // update after testing on dev to: var.transit_gateway_cidr
//  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.staging_api_vpc.id
//}
//

//
//// TODO: set up aws cross account access role for Staging APIs account
//// not sure if aws api staging provider config correctly, also need credentials
//
//resource "aws_iam_role" "vpc_peering" {
//  tags = module.tags.values
//
//  name               = "${local.identifier_prefix}-vpc-accepter-peering"
//  assume_role_policy = data.aws_iam_policy_document.vpc_peering_accepter.json
//}
//
//data "aws_iam_policy_document" "vpc_peering_accepter" {
//  statement {
//    actions = ["sts:AssumeRole"]
//
//    principals {
//      identifiers = ["ec2.amazonaws.com"]
//      type        = "Service"
//    }
//  }
//}
//
//data "aws_iam_policy" "amazon_ssm_managed_instance_core" {
//  name = "AmazonSSMManagedInstanceCore"
//}
//
//resource "aws_iam_role_policy_attachment" "bastion" {
//  policy_arn = data.aws_iam_policy.amazon_ssm_managed_instance_core.arn
//  role       = aws_iam_role.bastion.id
//}