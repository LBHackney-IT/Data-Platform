data "aws_secretsmanager_secret" "icaseworks_api_credentials_for_lambda" {
  name = "icaseworks-key"
}

data "aws_secretsmanager_secret_version" "icaseworks_api_credentials_for_lambda" {
  secret_id = data.aws_secretsmanager_secret.icaseworks_api_credentials_for_lambda.id
}

locals {
  secret_string = jsondecode(data.aws_secretsmanager_secret_version.icaseworks_api_credentials_for_lambda.secret_string)
  api_key       = local.secret_string["api_key"]
  secret        = local.secret_string["secret"]
  s3_target_bucket_name = module.landing_zone.bucket_id
  output_folder_name = "icaseworks"
}

module "icaseworks_api_ingestion" {
  source = "../modules/icaseworks-api-ingestion-lambda"
  tags   = module.tags.values

  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
  lambda_name                    = "icaseworks"
  secrets_manager_kms_key        = aws_kms_key.secrets_manager_key
  s3_target_bucket_arn           = module.landing_zone.bucket_arn
  s3_target_bucket_name          = local.s3_target_bucket_name
  s3_target_bucket_kms_key_arn   = module.landing_zone.kms_key_arn
  ephemeral_storage              = 6144
  lambda_environment_variables   = {
    "API_KEY" = local.api_key
    "SECRET" = local.secret
    "TARGET_S3_BUCKET_NAME" = local.s3_target_bucket_name
    "OUTPUT_FOLDER" = "icaseworks"
  }
}