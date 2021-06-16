module "liberator_data_sftp_to_s3" {
  source                = "../modules/liberator-sftp-to-s3"
  tags                  = module.tags.values
  identifier_prefix     = local.identifier_prefix
  s3_bucket_kms_key_arn = module.liberator_data_storage.kms_key_arn
  s3_bucket_arn         = module.liberator_data_storage.bucket_arn
  s3_bucket_id          = module.liberator_data_storage.bucket_id
  run_daily             = var.environment != "dev"

  lambda_artefact_storage_bucket_name = module.lambda_artefact_storage.bucket_id
}
