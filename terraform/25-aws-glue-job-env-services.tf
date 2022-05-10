resource "aws_s3_bucket_object" "aqs" {
  for_each    = fileset(path.module, "../jobs/env_services/aqs/*.json")
  bucket      = module.glue_scripts.bucket_id
  key         = "../jobs/env_services/aqs/${each.value}"
  acl         = "private"
  source      = "../jobs/env_services/aqs/${each.value}"
  source_hash = filemd5("../jobs/env_services/aqs/${each.value}")
}

resource "aws_glue_trigger" "alloy_daily_table_ingestion" {
  tags     = module.tags.values
  name     = "${local.short_identifier_prefix}Alloy Ingestion Trigger"
  type     = "SCHEDULED"
  schedule = "cron(0 23 ? * MON-FRI *)"
  enabled  = local.is_live_environment

  dynamic "actions" {
    for_each = fileset(path.module, "../jobs/env_services/aqs/*.json")
    content {
      job_name = module.alloy_api_ingestion_raw_env_services.job_name
      arguments = {
        "--aqs"      = file(actions.value)
        "--filename" = "trimsuffix(${actions.value},\".json\")/trimsuffix(${actions.value}, \".json\").csv"
        "--resource" = "trimsuffix(${actions.value},\".json\")"
      }
    }
  }
}

module "alloy_api_ingestion_raw_env_services" {
  job_description            = "This job queries the Alloy API for data and converts the exported csv to Parquet saved to S3"
  source                     = "../modules/aws-glue-job"
  department                 = module.department_environmental_services
  job_name                   = "${local.short_identifier_prefix}alloy_api_ingestion_env_services"
  helper_module_key          = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key            = aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage.bucket_id
  script_name                = "alloy_api_ingestion"
  job_parameters = {
    "--job-bookmark-option"     = "job-bookmark-enable"
    "--enable-glue-datacatalog" = "true"
    "--s3_bucket_target"        = module.raw_zone.bucket_id
    "--s3_prefix"               = "env-services/alloy/api-responses/"
    "--secret_name"             = "${local.identifier_prefix}/env-services/alloy-api-key"
    "--database"                = module.department_environmental_services.raw_zone_catalog_database_name
  }
  crawler_details = {
    database_name      = module.department_environmental_services.raw_zone_catalog_database_name
    s3_target_location = "s3://${module.raw_zone.bucket_id}/env/services/alloy/api_response"
    table_prefix       = "alloy_"
  }
}
