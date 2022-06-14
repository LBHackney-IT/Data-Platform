module "icaseworks_api_ingestion" {
  source = "../modules/icaseworks-api-ingestion-lambda"
  tags   = module.tags.values

  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
  lambda_name                    = "icaseworks"
  output_folder_name             = "icaseworks"
  secrets_manager_kms_key        = aws_kms_key.secrets_manager_key
  api_credentials_secret_name    = "icaseworks-key"
  s3_target_bucket_arn           = module.landing_zone.bucket_arn
  s3_target_bucket_name          = module.landing_zone.bucket_id
  s3_target_bucket_kms_key_arn   = module.landing_zone.kms_key_arn
  ephemeral_storage              = 6144
}