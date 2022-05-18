locals {
  alloy_queries                     = local.is_live_environment ? fileset(path.module, "../scripts/jobs/env_services/aqs/*json") : []
  alloy_queries_max_concurrent_runs = local.is_live_environment ? length(local.alloy_queries) : 1
}

resource "aws_glue_trigger" "alloy_daily_table_ingestion" {
  tags     = module.tags.values
  enabled  = local.is_live_environment
  for_each = local.alloy_queries

  name     = "${local.short_identifier_prefix}${each.value} Alloy Ingestion Job"
  type     = "SCHEDULED"
  schedule = "cron(0 23 ? * MON-FRI *)"

  actions {
    job_name = module.alloy_api_ingestion_raw_env_services[0].job_name
    arguments = {
      "--aqs"      = file(each.value)
      "--filename" = "trimsuffix(${each.value},\".json\")/trimsuffix(${each.value}, \".json\").csv"
      "--resource" = "trimsuffix(${each.value},\".json\")"
    }
  }
}

module "alloy_api_ingestion_raw_env_services" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  job_description                 = "This job queries the Alloy API for data and converts the exported csv to Parquet saved to S3"
  source                          = "../modules/aws-glue-job"
  department                      = module.department_environmental_services
  job_name                        = "${local.short_identifier_prefix}alloy_api_ingestion_env_services"
  helper_module_key               = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id      = module.spark_ui_output_storage.bucket_id
  trigger_enabled                 = false
  max_concurrent_runs_of_glue_job = local.alloy_queries_max_concurrent_runs
  script_name                     = "alloy_api_ingestion"
  job_parameters = {
    "--job-bookmark-option"     = "job-bookmark-enable"
    "--enable-glue-datacatalog" = "true"
    "--s3_bucket_target"        = module.raw_zone.bucket_id
    "--s3_prefix"               = "env-services/alloy/api-responses/"
    "--table_prefix"            = "alloy_api_response_"
    "--secret_name"             = "${local.identifier_prefix}/env-services/alloy-api-key"
    "--database"                = module.department_environmental_services.raw_zone_catalog_database_name
  }
}

resource "aws_glue_trigger" "alloy_daily_table_ingestion_crawler" {
  count   = local.is_live_environment ? 1 : 0
  tags    = module.tags.values
  name    = "${local.short_identifier_prefix}Alloy Ingestion Crawler"
  type    = "CONDITIONAL"
  enabled = local.is_live_environment

  actions {
    crawler_name = aws_glue_crawler.alloy_daily_table_ingestion[0].name
  }

  predicate {
    conditions {
      job_name = module.alloy_api_ingestion_raw_env_services[0].job_name
      state    = "SUCCEEDED"
    }
  }
}

resource "aws_glue_crawler" "alloy_daily_table_ingestion" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  database_name = module.department_environmental_services.raw_zone_catalog_database_name
  name          = "${local.short_identifier_prefix}Alloy Ingestion"
  role          = module.department_environmental_services.glue_role_arn

  s3_target {
    path = "s3://${module.raw_zone.bucket_id}/env-services/alloy/api-responses/"
  }
  table_prefix = "alloy_api_response_"

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 5
    }
  })
}
