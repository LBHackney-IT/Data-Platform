locals {
  s3_target_bucket_name = module.landing_zone.bucket_id
  secret_name           = "icaseworks-key"
}

module "icaseworks_api_ingestion" {
  source = "../modules/api-ingestion-lambda"
  tags   = module.tags.values

  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
  lambda_name                    = "icaseworks-api-ingestion"
  secrets_manager_kms_key        = aws_kms_key.secrets_manager_key
  s3_target_bucket_arn           = module.landing_zone.bucket_arn
  s3_target_bucket_name          = local.s3_target_bucket_name
  api_credentials_secret_name    = local.secret_name
  s3_target_bucket_kms_key_arn   = module.landing_zone.kms_key_arn
  ephemeral_storage              = 6144
  lambda_environment_variables = {
    "SECRET_NAME"           = local.secret_name
    "TARGET_S3_BUCKET_NAME" = local.s3_target_bucket_name
    "OUTPUT_FOLDER"         = "icaseworks"
  }
}