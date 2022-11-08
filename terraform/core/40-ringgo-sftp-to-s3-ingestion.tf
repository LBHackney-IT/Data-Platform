locals {
  glue_trigger_name     = local.is_live_environment ? module.ringgo_sftp_data_to_raw[0].trigger_name : ""
}

module "sftp_to_s3_ingestion" {
  count                     = local.is_live_environment ? 1 : 0
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
  
  lambda_environment_variables = {
    "SFTP_HOST"                   = local.sftp_server_host
    "SFTP_USERNAME"               = local.sftp_server_username
    "SFTP_PASSWORD"               = local.sftp_server_password
    "SFTP_SOURCE_FILE_PREFIX"     = "data_warehouse_-"
    "SFTP_TARGET_FILE_PATH"       = "/client/"
    "SFTP_SOURCE_FILE_EXTENSION"  = "csv"
    "S3_BUCKET"                   = module.landing_zone.bucket_id
    "S3_TARGET_FOLDER"            = "ringgo/sftp/input"
  }
  lambda_execution_cron_schedule  = "cron(0 21 * * ? *)"
  trigger_to_run                  = local.glue_trigger_name
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

resource "aws_glue_catalog_database" "parking_ringgo_sftp_catalog_database" {
  count = local.is_live_environment ? 1 : 0
  name  = "${local.short_identifier_prefix}parking-ringgo-sftp-raw-zone"
  
  lifecycle {
    prevent_destroy = true
  }
}

module "ringgo_sftp_data_to_raw" {
  source = "../modules/aws-glue-job"
  count                      = local.is_live_environment ? 1 : 0
  is_production_environment  = local.is_production_environment
  is_live_environment        = local.is_live_environment
  job_name                   = "${local.short_identifier_prefix}Parking copy RingGo SFTP data to raw"
  helper_module_key          = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key            = aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage.bucket_id
  
  glue_scripts_bucket_id     = module.glue_scripts.bucket_id
  glue_temp_bucket_id        = module.glue_temp_storage.bucket_id
  glue_role_arn              = aws_iam_role.glue_role.arn
  script_s3_object_key       = aws_s3_bucket_object.parking_copy_ringgo_sftp_data_to_raw.key
  
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-enable"
    "--s3_bucket_target"    = "${module.raw_zone.bucket_id}/parking"
    "--s3_bucket_source"    = module.landing_zone.bucket_id
    "--s3_prefix"           = "ringgo/sftp/"
    "--extra-py-files"      = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
  
  trigger_enabled      = local.is_production_environment
  
  crawler_details = {
    database_name      = aws_glue_catalog_database.parking_ringgo_sftp_catalog_database[0].name
    s3_target_location = "s3://${module.raw_zone.bucket_id}/parking/ringgo/"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableLevelConfiguration = 4
      }
    })
  }
}
