module "redshift" {
  count = terraform.workspace == "default" ? 1 : 0

  source                   = "../modules/redshift"
  tags                     = module.tags.values
  identifier_prefix        = local.identifier_prefix
  subnet_ids_list          = local.subnet_ids_list
  vpc_id                   = data.aws_vpc.network.id
  landing_zone_bucket_arn  = module.landing_zone.bucket_arn
  refined_zone_bucket_arn  = module.refined_zone.bucket_arn
  trusted_zone_bucket_arn  = module.trusted_zone.bucket_arn
  raw_zone_bucket_arn      = module.raw_zone.bucket_arn
  landing_zone_kms_key_arn = module.landing_zone.kms_key_arn
  raw_zone_kms_key_arn     = module.raw_zone.kms_key_arn
  refined_zone_kms_key_arn = module.refined_zone.kms_key_arn
  trusted_zone_kms_key_arn = module.trusted_zone.kms_key_arn
  secrets_manager_key      = aws_kms_key.secrets_manager_key.arn
}
