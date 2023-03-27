locals {
  s3_target_bucket_name    = module.landing_zone.bucket_id
  secret_name              = "icaseworks-key"
  glue_trigger_name        = local.is_live_environment ? module.copy_icaseworks_data_landing_to_raw[0].trigger_name : ""
  vonage_glue_trigger_name = local.is_live_environment ? module.copy_vonage_data_landing_to_raw[0].trigger_name : ""
}

module "icaseworks_api_ingestion" {
  count                     = local.is_live_environment ? 1 : 0
  source                    = "../modules/api-ingestion-lambda"
  tags                      = module.tags.values
  is_production_environment = local.is_production_environment
  is_live_environment       = local.is_live_environment

  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
  lambda_name                    = "icaseworks-api-ingestion"
  lambda_handler                 = "main.lambda_handler"
  runtime_language               = "python3.8"
  secrets_manager_kms_key        = aws_kms_key.secrets_manager_key
  s3_target_bucket_arn           = module.landing_zone.bucket_arn
  s3_target_bucket_name          = local.s3_target_bucket_name
  api_credentials_secret_name    = local.secret_name
  trigger_to_run                 = local.glue_trigger_name
  s3_target_bucket_kms_key_arn   = module.landing_zone.kms_key_arn
  ephemeral_storage              = 6144
  lambda_environment_variables   = {
    "SECRET_NAME"           = local.secret_name
    "TARGET_S3_BUCKET_NAME" = local.s3_target_bucket_name
    "OUTPUT_FOLDER"         = "icaseworks"
    "TRIGGER_NAME"          = local.glue_trigger_name
  }

}

module "vonage_api_ingestion" {
  count                     = local.is_live_environment ? 1 : 0
  source                    = "../modules/api-ingestion-lambda"
  tags                      = module.tags.values
  is_production_environment = local.is_production_environment
  is_live_environment       = local.is_live_environment

  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
  lambda_name                    = "vonage-api-ingestion"
  lambda_handler                 = "main.lambda_handler"
  runtime_language               = "python3.8"
  secrets_manager_kms_key        = aws_kms_key.secrets_manager_key
  s3_target_bucket_arn           = module.landing_zone.bucket_arn
  s3_target_bucket_name          = local.s3_target_bucket_name
  api_credentials_secret_name    = "/customer-services/vonage-key"
  s3_target_bucket_kms_key_arn   = module.landing_zone.kms_key_arn
  trigger_to_run                 = local.vonage_glue_trigger_name
  lambda_memory_size             = 1024
  lambda_environment_variables   = {
    "SECRET_NAME"           = "/customer-services/vonage-key"
    "TARGET_S3_BUCKET_NAME" = local.s3_target_bucket_name
    "OUTPUT_FOLDER"         = "customer-services/manual/vonage"
    "TRIGGER_NAME"          = local.vonage_glue_trigger_name
    "API_TO_CALL"           = "stats"
    "TABLE_TO_CALL"         = "interactions"
  }
}

module "copy_icaseworks_data_landing_to_raw" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  count = local.is_live_environment ? 1 : 0

  job_name                       = "${local.short_identifier_prefix}iCaseworks (OneCase) Copy Landing to Raw"
  glue_role_arn                  = aws_iam_role.glue_role.arn
  helper_module_key              = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage.bucket_id
  script_s3_object_key           = aws_s3_bucket_object.copy_json_data_landing_to_raw.key
  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
  glue_temp_bucket_id            = module.glue_temp_storage.bucket_id
  environment                    = var.environment
  trigger_enabled                = local.is_production_environment
  number_of_workers_for_glue_job = 2
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters                 = {
    "--job-bookmark-option" = "job-bookmark-enable"
    "--s3_bucket_target"    = "${module.raw_zone.bucket_id}/data-and-insight"
    "--s3_bucket_source"    = module.landing_zone.bucket_id
    "--s3_prefix"           = "icaseworks/"
    "--extra-py-files"      = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
  crawler_details = {
    database_name      = module.department_data_and_insight.raw_zone_catalog_database_name
    s3_target_location = "s3://${module.raw_zone.bucket_id}/data-and-insight/icaseworks/"
    configuration      = jsonencode({
      Version  = 1.0
      Grouping = {
        TableLevelConfiguration = 3
      }
    })
  }
}

module "copy_vonage_data_landing_to_raw" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  count = local.is_live_environment && !local.is_production_environment ? 1 : 0

  job_name                   = "${local.short_identifier_prefix}Vonage Copy Landing to Raw"
  glue_role_arn              = aws_iam_role.glue_role.arn
  helper_module_key          = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key            = aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage.bucket_id
  script_s3_object_key       = aws_s3_bucket_object.vonage_landing_to_raw.key
  glue_scripts_bucket_id     = module.glue_scripts.bucket_id
  glue_temp_bucket_id        = module.glue_temp_storage.bucket_id
  environment                = var.environment
  trigger_enabled            = local.is_production_environment
  number_of_workers_for_glue_job = 2
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters             = {
    "--job-bookmark-option" = "job-bookmark-enable"
    "--raw_zone_bucket"     = module.raw_zone.bucket_id
    "--landing_zone_bucket" = module.landing_zone.bucket_id
    "--landing_zone_prefix" = "customer-services/manual/vonage"
    "--raw_zone_prefix"     = "customer-services/vonage"
    "--extra-py-files"      = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
  crawler_details = {
    database_name      = module.department_customer_services.raw_zone_catalog_database_name
    s3_target_location = "s3://${module.raw_zone.bucket_id}/customer-services/vonage/"
    configuration      = jsonencode({
      Version  = 1.0
      Grouping = {
        TableLevelConfiguration = 3
      }
    })
  }
}
