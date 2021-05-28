module "liberator_data_sftp_to_s3" {
  source                   = "../modules/liberator-sftp-to-s3"
  tags                     = module.tags.values
  identifier_prefix        = local.identifier_prefix
  landing_zone_kms_key_arn = module.landing_zone.kms_key_arn
  landing_zone_bucket_arn  = module.landing_zone.bucket_arn
  landing_zone_bucket_id   = module.landing_zone.bucket_id
}
