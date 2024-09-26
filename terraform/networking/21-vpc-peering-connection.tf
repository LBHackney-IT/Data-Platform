locals {
  requester_assume_role_arn           = "arn:aws:iam::${var.aws_deploy_account_id}:role/${var.aws_deploy_iam_role_name}"
  aws_api_accepter_assume_role_arn    = "arn:aws:iam::${var.aws_api_account_id}:role/${var.aws_deploy_iam_role_name}"
  aws_mosaic_accepter_assume_role_arn = "arn:aws:iam::${var.aws_mosaic_prod_account_id}:role/${var.aws_deploy_iam_role_name}"
  accepter_assume_role_arn            = "arn:aws:iam::${var.aws_data_platform_account_id}:role/${var.aws_deploy_iam_role_name}"
}

module "api_vpc_peering_cross_account" {
  tags    = module.tags.values
  enabled = false

  source = "git::https://github.com/cloudposse/terraform-aws-vpc-peering-multi-account.git?ref=tags/0.19.1"
  name   = "${local.identifier_prefix}-api-vpc-peering-connection"

  requester_aws_assume_role_arn             = local.requester_assume_role_arn
  requester_region                          = var.aws_deploy_region
  requester_vpc_id                          = module.core_vpc.vpc_id
  requester_allow_remote_vpc_dns_resolution = "false"
  accepter_aws_profile                      = "terraform"
  accepter_aws_assume_role_arn              = local.aws_api_accepter_assume_role_arn
  accepter_region                           = var.aws_deploy_region
  accepter_vpc_id                           = var.aws_api_vpc_id
  accepter_allow_remote_vpc_dns_resolution  = "false"
  requester_aws_profile                     = "terraform"
}

module "dp_stg_prod_vpc_peering_cross_account" {
  tags    = module.tags.values
  enabled = false

  source = "git::https://github.com/cloudposse/terraform-aws-vpc-peering-multi-account.git?ref=tags/0.19.1"
  name   = "${local.identifier_prefix}-vpc-peering-connection"

  requester_aws_assume_role_arn             = local.requester_assume_role_arn
  requester_region                          = var.aws_deploy_region
  requester_vpc_id                          = module.core_vpc.vpc_id
  requester_allow_remote_vpc_dns_resolution = "true"

  accepter_aws_assume_role_arn             = local.accepter_assume_role_arn
  accepter_region                          = var.aws_deploy_region
  accepter_vpc_id                          = var.aws_dp_vpc_id
  accepter_allow_remote_vpc_dns_resolution = "false"
}
#
