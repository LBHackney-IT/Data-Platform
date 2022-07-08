module "sftp_to_s3_ingestion" {
  count  = local.is_live_environment ? 1 : 0
  source = "../modules/api-ingestion-lambda"
  tags   = module.tags.values

  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
  lambda_name                    = "sftp-to-s3"
  lambda_handler                 = "index.handler"
  runtime_language               = "nodejs14.x"
  secrets_manager_kms_key        = aws_kms_key.secrets_manager_key
  s3_target_bucket_arn           = module.landing_zone.bucket_arn
  s3_target_bucket_name          = local.s3_target_bucket_name
  api_credentials_secret_name    = local.secret_name
  glue_job_to_trigger            = local.glue_job_name
  s3_target_bucket_kms_key_arn   = module.landing_zone.kms_key_arn
  ephemeral_storage              = 6144
  lambda_environment_variables = {
    "SFTP_HOST"         = local.sftp_server_host.value
    "SFTP_USERNAME"     = local.sftp_server_username.value
    "SFTP_PASSWORD"     = local.sftp_server_password.value
    "S3_BUCKET"         = var.s3_target_bucket_id
    "OBJECT_KEY_PREFIX" = "${var.department_identifier}"
  }
}