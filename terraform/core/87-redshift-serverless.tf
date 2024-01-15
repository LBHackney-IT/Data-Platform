module "redshift_serverless" {
  count                                 = local.is_live_environment && !local.is_production_environment ? 1 : 0
  source                                = "../modules/redshift-serverless"
  tags                                  = module.tags.values
  subnet_ids                            = local.subnet_ids_list
  identifier_prefix                     = local.identifier_prefix
  secrets_manager_key                   = aws_kms_key.secrets_manager_key.id
  vpc_id                                = data.aws_vpc.network.id
  namespace_name                        = "${local.identifier_prefix}-redshift-serverless"
  workgroup_name                        = "${local.identifier_prefix}-default"
  admin_username                        = "data_engineers"
  db_name                               = "data_platform"
  workgroup_base_capacity               = 32
  serverless_compute_usage_limit_period = "daily"
  serverless_compute_usage_limit_amount = 1
  landing_zone_bucket_arn               = module.landing_zone.bucket_arn
  refined_zone_bucket_arn               = module.refined_zone.bucket_arn
  trusted_zone_bucket_arn               = module.trusted_zone.bucket_arn
  raw_zone_bucket_arn                   = module.raw_zone.bucket_arn
  landing_zone_kms_key_arn              = module.landing_zone.kms_key_arn
  raw_zone_kms_key_arn                  = module.raw_zone.kms_key_arn
  refined_zone_kms_key_arn              = module.refined_zone.kms_key_arn
  trusted_zone_kms_key_arn              = module.trusted_zone.kms_key_arn
}

