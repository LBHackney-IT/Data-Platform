locals {
  alloy_queries                     = fileset("${path.module}/../scripts/jobs/env_services/aqs", "*json")
  alloy_query_names                 = [for i in tolist(local.alloy_queries) : trimsuffix(i, ".json")]
  alloy_queries_max_concurrent_runs = length(local.alloy_queries)
  //alloy_queries                     = local.is_live_environment ? fileset("${path.module}/../scripts/jobs/env_services/aqs", "*json") : []
  //alloy_query_names                 = [for i in local.alloy_queries : trimsuffix(i, ".json")]
  //alloy_queries_max_concurrent_runs = local.is_live_environment ? length(local.alloy_queries) : 1
}

resource "aws_glue_trigger" "alloy_daily_table_ingestion" {
  count = length(local.alloy_queries)
  //count   = local.is_live_environment ? "${length(local.alloy_queries)}" : 0
  tags    = module.tags.values
  enabled = local.is_live_environment


  name     = "${local.short_identifier_prefix} ${local.alloy_query_names[count.index]} Alloy Ingestion Job"
  type     = "SCHEDULED"
  schedule = "cron(0 23 ? * MON-FRI *)"

  actions {
    job_name = module.alloy_api_ingestion_raw_env_services[count.index].job_name
  }
}

module "alloy_api_ingestion_raw_env_services" {
  source = "../modules/aws-glue-job"
  count  = length(local.alloy_queries)
  //count  = local.is_live_environment ? "${length(local.alloy_queries)}" : 0

  job_description                 = "This job queries the Alloy API for data and converts the exported csv to Parquet saved to S3"
  department                      = module.department_environmental_services
  job_name                        = "${local.short_identifier_prefix}_${local.alloy_query_names[count.index]}_alloy_api_ingestion_env_services"
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
    "--secret_name"             = "${local.identifier_prefix}/env-services/alloy-api-key"
    "--database"                = module.department_environmental_services.raw_zone_catalog_database_name
    "--aqs"                     = file("${path.module}/../scripts/jobs/env_services/aqs/${tolist(local.alloy_queries)[count.index]}")
    "--filename"                = "${local.alloy_query_names[count.index]}/${local.alloy_query_names[count.index]}.csv"
    "--resource"                = "${local.alloy_query_names[count.index]}"
  }
}



resource "aws_glue_trigger" "alloy_daily_table_ingestion_crawler" {

  count = length(local.alloy_queries)
  //count = local.is_live_environment ? "${length(local.alloy_queries)}" : 0
  tags    = module.tags.values
  name    = "${local.short_identifier_prefix} ${local.alloy_query_names[count.index]} Alloy Ingestion Crawler"
  type    = "CONDITIONAL"
  enabled = local.is_live_environment

  actions {
    crawler_name = aws_glue_crawler.alloy_daily_table_ingestion[count.index].name
  }

  predicate {
    conditions {
      job_name = module.alloy_api_ingestion_raw_env_services[count.index].job_name
      state    = "SUCCEEDED"
    }
  }
}

resource "aws_glue_crawler" "alloy_daily_table_ingestion" {
  count = length(local.alloy_queries)
  //count = local.is_live_environment ? "${length(local.alloy_queries)}" : 0
  tags = module.tags.values

  database_name = module.department_environmental_services.raw_zone_catalog_database_name
  name          = "${local.short_identifier_prefix}Alloy Ingestion ${local.alloy_query_names[count.index]}"
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

resource "aws_glue_trigger" "alloy_daily_snapshot" {
  count = length(local.alloy_queries)
  //count   = local.is_live_environment ? "${length(local.alloy_queries)}" : 0
  tags    = module.tags.values
  enabled = local.is_live_environment


  name = "${local.short_identifier_prefix} ${local.alloy_query_names[count.index]} Alloy Snapshot Job"
  type = "CONDITIONAL"

  actions {
    job_name = module.alloy_daily_snapshot_env_services[count.index].job_name
  }

  predicate {
    conditions {
      crawler_name = aws_glue_crawler.alloy_daily_table_ingestion[count.index].name
      crawl_state  = "SUCCEEDED"
    }
  }
}

module "alloy_daily_snapshot_env_services" {
  source = "../modules/aws-glue-job"
  count  = length(local.alloy_queries)
  //count  = local.is_live_environment ? "${length(local.alloy_queries)}" : 0

  job_description                 = "This job combines previous updates from the API to create a daily snapshot"
  department                      = module.department_environmental_services
  job_name                        = "${local.short_identifier_prefix}_${local.alloy_query_names[count.index]}_alloy_snapshot_env_services"
  helper_module_key               = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id      = module.spark_ui_output_storage.bucket_id
  trigger_enabled                 = false
  max_concurrent_runs_of_glue_job = local.alloy_queries_max_concurrent_runs
  script_name                     = "alloy_create_snapshot"
  job_parameters = {
    "--job-bookmark-option"        = "job-bookmark-enable"
    "--enable-glue-datacatalog"    = "true"
    "--snapshot_catalog_database"  = "env-services-refined-zone"
    "--increment_catalog_database" = "env-services-raw-zone"
    "--table_name"                 = lower(replace(local.alloy_query_names[count.index], " ", "_"))
    "--increment_prefix"           = "alloy_api_response_"
    "--snapshot_prefix"            = "alloy_snapshot_"
    "--id_col"                     = "item_id"
    "--increment_date_col "        = "import_datetime"
    "--snapshot_date_col"          = "snapshot_date"
    "s3_bucket_target"             = "s3://dataplatform-stg-refined-zone/env-services/alloy/snapshots/"

  }
}
