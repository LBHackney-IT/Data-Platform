module "sftp_to_s3_ingestion" {
  count                     = local.is_live_environment ? 1 : 1
  source                    = "../modules/api-ingestion-lambda"
  tags                      = module.tags.values
  is_production_environment = local.is_production_environment
  is_live_environment       = local.is_live_environment


  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
  lambda_name                    = "sftp-to-s3"
  lambda_handler                 = "index.handler"
  runtime_language               = "nodejs14.x"
  secrets_manager_kms_key        = aws_kms_key.secrets_manager_key
  s3_target_bucket_arn           = module.landing_zone.bucket_arn
  s3_target_bucket_name          = module.landing_zone.bucket_id
  api_credentials_secret_name    = "ringo-daily-sftp-credentials"
  s3_target_bucket_kms_key_arn   = module.landing_zone.kms_key_arn
  ephemeral_storage              = 6144
  lambda_environment_variables = {
    "SFTP_HOST"          = local.sftp_server_host
    "SFTP_USERNAME"      = local.sftp_server_username
    "SFTP_PASSWORD"      = local.sftp_server_password
    "S3_BUCKET"          = module.landing_zone.bucket_id
    "TARGET_KEY_PREFIX"  = "parking/ringo/"
    "SOURCE_FILE_PREFIX" = "data_warehouse_-"
    "TARGET_FILE_PREFIX" = "ringo"
  }
}

data "aws_secretsmanager_secret" "sftp_server_credentials" {
  name = "ringo-daily-sftp-credentials"
}

data "aws_secretsmanager_secret_version" "sftp_server_credentials" {
  secret_id = data.aws_secretsmanager_secret.sftp_server_credentials.id
}

locals {
  secret_string        = jsondecode(data.aws_secretsmanager_secret_version.sftp_server_credentials.secret_string)
  sftp_server_host     = local.secret_string["sftp_server_host"]
  sftp_server_username = local.secret_string["sftp_server_username"]
  sftp_server_password = local.secret_string["sftp_server_password"]
}
