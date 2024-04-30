module "copy_from_s3_to_s3" {
  source = "../modules/copy-from-s3-to-s3"
  tags   = module.tags.values

  is_live_environment            = local.is_live_environment
  environment                    = local.environment
  is_production_environment      = local.is_production_environment
  lambda_name                    = "rentsense-s3-to-s3-export-copy"
  identifier_prefix              = local.identifier_prefix
  short_identifier_prefix        = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage
  lambda_execution_cron_schedule = "cron(0 8 * * ? *)"
  origin_bucket                  = module.refined_zone
  origin_path                    = "housing/rentsense/export/"
  target_bucket = {
    bucket_id   = "feeds-pluto-mobysoft"
    bucket_arn  = "arn:aws:s3:::feeds-pluto-mobysoft"
    kms_key_id  = null
    kms_key_arn = null
  }
  target_path = var.rentsense_target_path
  assume_role = "arn:aws:iam::971933469343:role/customer-midas-roles-pluto-HackneyMidasRole-1M6PTJ5VS8104"
}

module "copy_from_s3_to_s3_ft" {
  source = "../modules/copy-from-s3-to-s3"
  tags   = module.tags.values

  is_live_environment            = local.is_live_environment
  environment                    = local.environment
  is_production_environment      = local.is_production_environment
  lambda_name                    = "rentsense-ft-s3-to-s3-export"
  identifier_prefix              = local.identifier_prefix
  short_identifier_prefix        = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage
  runtime                        = "nodejs16.x"
  lambda_execution_cron_schedule = "cron(0 8 * * ? *)"
  origin_bucket                  = module.refined_zone
  origin_path                    = "housing/rentsense-ft/export/"
  target_bucket = {
    bucket_id   = "feeds-pluto-mobysoft"
    bucket_arn  = "arn:aws:s3:::feeds-pluto-mobysoft"
    kms_key_id  = null
    kms_key_arn = null
  }
  target_path = var.rentsense_ft_target_path
  assume_role = "arn:aws:iam::971933469343:role/customer-midas-roles-pluto-HackneyMidasRole-1M6PTJ5VS8104"
}
