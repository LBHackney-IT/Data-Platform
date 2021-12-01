locals {
  requester_assume_role_arn            = "arn:aws:iam::${var.aws_deploy_account}:role/${var.aws_deploy_iam_role_name}"
  aws_api_accepter_assume_role_arn     = "arn:aws:iam::${var.aws_api_account}:role/${var.aws_deploy_iam_role_name}"
  aws_housing_accepter_assume_role_arn = "arn:aws:iam::${var.aws_housing_prod_account_id}:role/${var.aws_deploy_iam_role_name}"
  aws_mosaic_accepter_assume_role_arn  = "arn:aws:iam::${var.aws_mosaic_prod_account_id}:role/${var.aws_deploy_iam_role_name}"
}

#module "vpc_peering_cross_account" {
#  tags = module.tags.values
#
#  source = "git::https://github.com/cloudposse/terraform-aws-vpc-peering-multi-account.git?ref=tags/0.16.0"
#  name   = "${local.identifier_prefix}-vpc-peering-connection"
#
#  requester_aws_assume_role_arn             = local.requester_assume_role_arn
#  requester_region                          = var.aws_deploy_region
#  requester_vpc_id                          = module.core_vpc.vpc_id
#  requester_allow_remote_vpc_dns_resolution = "true"
#
#  accepter_aws_assume_role_arn             = local.aws_api_accepter_assume_role_arn
#  accepter_region                          = var.aws_deploy_region
#  accepter_vpc_id                          = var.aws_api_vpc_id
#  accepter_allow_remote_vpc_dns_resolution = "false"
#}

module "api_vpc_peering_cross_account" {
  tags = module.tags.values

  source = "git::https://github.com/cloudposse/terraform-aws-vpc-peering-multi-account.git?ref=tags/0.16.0"
  name   = "${local.identifier_prefix}-api-vpc-peering-connection"

  requester_aws_assume_role_arn             = local.requester_assume_role_arn
  requester_region                          = var.aws_deploy_region
  requester_vpc_id                          = module.core_vpc.vpc_id
  requester_allow_remote_vpc_dns_resolution = "true"

  accepter_aws_assume_role_arn             = local.aws_api_accepter_assume_role_arn
  accepter_region                          = var.aws_deploy_region
  accepter_vpc_id                          = var.aws_api_vpc_id
  accepter_allow_remote_vpc_dns_resolution = "false"
}

module "housing_vpc_peering_cross_account" {
  tags = module.tags.values

  source = "git::https://github.com/cloudposse/terraform-aws-vpc-peering-multi-account.git?ref=tags/0.16.0"
  name   = "${local.identifier_prefix}-housing-vpc-peering-connection"

  requester_aws_assume_role_arn             = local.requester_assume_role_arn
  requester_region                          = var.aws_deploy_region
  requester_vpc_id                          = module.core_vpc.vpc_id
  requester_allow_remote_vpc_dns_resolution = "true"

  accepter_aws_assume_role_arn             = local.aws_housing_accepter_assume_role_arn
  accepter_region                          = var.aws_deploy_region
  accepter_vpc_id                          = var.aws_housing_vpc_id
  accepter_allow_remote_vpc_dns_resolution = "false"
}

module "mosaic_vpc_peering_cross_account" {
  tags = module.tags.values

  source = "git::https://github.com/cloudposse/terraform-aws-vpc-peering-multi-account.git?ref=tags/0.16.0"
  name   = "${local.identifier_prefix}-mosaic-vpc-peering-connection"

  requester_aws_assume_role_arn             = local.requester_assume_role_arn
  requester_region                          = var.aws_deploy_region
  requester_vpc_id                          = module.core_vpc.vpc_id
  requester_allow_remote_vpc_dns_resolution = "true"

  accepter_aws_assume_role_arn             = local.aws_mosaic_accepter_assume_role_arn
  accepter_region                          = var.aws_deploy_region
  accepter_vpc_id                          = var.aws_mosaic_vpc_id
  accepter_allow_remote_vpc_dns_resolution = "false"
}
