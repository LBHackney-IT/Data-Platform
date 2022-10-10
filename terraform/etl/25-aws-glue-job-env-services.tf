locals {
  alloy_queries                     = local.is_live_environment ? fileset("${path.module}/../../scripts/jobs/env_services/aqs", "*json") : []
  alloy_query_names                 = local.is_live_environment ? [for i in tolist(local.alloy_queries) : trimsuffix(i, ".json")] : []
  alloy_queries_max_concurrent_runs = local.is_live_environment ? length(local.alloy_queries) : 1
}

resource "aws_glue_trigger" "alloy_daily_table_ingestion" {
  count   = local.is_production_environment ? length(local.alloy_queries) : 0
  tags    = module.tags.values
  enabled = local.is_production_environment

  name     = "${local.short_identifier_prefix} ${local.alloy_query_names[count.index]} Alloy Ingestion Job"
  type     = "SCHEDULED"
  schedule = "cron(0 23 ? * MON-FRI *)"

  actions {
    job_name = module.alloy_api_ingestion_raw_env_services[count.index].job_name
  }
}

module "alloy_api_ingestion_raw_env_services" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment
  count                     = local.is_live_environment ? length(local.alloy_queries) : 0

  job_description = "This job queries the Alloy API for data and converts the exported csv to Parquet saved to S3"
  department      = module.department_environmental_services_data_source
  job_name        = "${local.short_identifier_prefix}_${local.alloy_query_names[count.index]}_alloy_api_ingestion_env_services"

  helper_module_key          = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key            = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  trigger_enabled            = false
  script_name                = "alloy_api_ingestion"
  job_parameters = {
    "--job-bookmark-option"     = "job-bookmark-enable"
    "--enable-glue-datacatalog" = "true"
    "--s3_bucket_target"        = module.raw_zone_data_source.bucket_id
    "--s3_prefix"               = "env-services/alloy/api-responses/"
    "--secret_name"             = "${local.identifier_prefix}/env-services/alloy-api-key"
    "--database"                = module.department_environmental_services_data_source.raw_zone_catalog_database_name
    "--aqs"                     = file("${path.module}/../../scripts/jobs/env_services/aqs/${tolist(local.alloy_queries)[count.index]}")
    "--resource"                = local.alloy_query_names[count.index]
    "--alloy_download_bucket"   = "env-services/alloy/alloy_api_downloads/"
    "--table_prefix"            = "alloy_api_response_"
  }
}



resource "aws_glue_trigger" "alloy_daily_table_ingestion_crawler" {
  count   = local.is_production_environment ? length(local.alloy_queries) : 0
  tags    = module.tags.values
  name    = "${local.short_identifier_prefix} ${local.alloy_query_names[count.index]} Alloy Ingestion Crawler"
  type    = "CONDITIONAL"
  enabled = local.is_production_environment

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
  count = local.is_live_environment ? length(local.alloy_queries) : 0
  tags  = module.tags.values

  database_name = module.department_environmental_services_data_source.raw_zone_catalog_database_name
  name          = "${local.short_identifier_prefix}Alloy Ingestion ${local.alloy_query_names[count.index]}"
  role          = module.department_environmental_services_data_source.glue_role_arn

  s3_target {
    path = "s3://${module.raw_zone_data_source.bucket_id}/env-services/alloy/api-responses/"
  }
  table_prefix = "alloy_api_response_"

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 5
    }
  })
}

module "alloy_daily_snapshot_env_services" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment
  count                     = local.is_live_environment ? length(local.alloy_queries) : 0

  job_description = "This job combines previous updates from the API to create a daily snapshot"
  department      = module.department_environmental_services_data_source
  job_name        = "${local.short_identifier_prefix}_${local.alloy_query_names[count.index]}_alloy_snapshot_env_services"

  helper_module_key          = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key            = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  triggered_by_crawler       = aws_glue_crawler.alloy_daily_table_ingestion[count.index].name
  script_name                = "alloy_create_snapshot"
  job_parameters = {
    "--job-bookmark-option"        = "job-bookmark-enable"
    "--enable-glue-datacatalog"    = "true"
    "--snapshot_catalog_database"  = "env-services-refined-zone"
    "--increment_catalog_database" = "env-services-raw-zone"
    "--table_name"                 = lower(replace(local.alloy_query_names[count.index], " ", "_"))
    "--increment_prefix"           = "alloy_api_response_"
    "--snapshot_prefix"            = "alloy_snapshot_"
    "--id_col"                     = "item_id"
    "--increment_date_col"         = "import_datetime"
    "--snapshot_date_col"          = "snapshot_date"
    "--s3_bucket_target"           = "s3://${module.refined_zone_data_source.bucket_id}/env-services/alloy/snapshots/"
    "--s3_mapping_bucket"          = module.raw_zone_data_source.bucket_id
  }
}

resource "aws_glue_trigger" "alloy_snapshot_crawler" {
  count   = local.is_live_environment ? length(local.alloy_queries) : 0
  tags    = module.tags.values
  name    = "${local.short_identifier_prefix} ${local.alloy_query_names[count.index]} Alloy Snapshot Crawler"
  type    = "CONDITIONAL"
  enabled = local.is_production_environment

  actions {
    crawler_name = aws_glue_crawler.alloy_snapshot[count.index].name
  }

  predicate {
    conditions {
      job_name = module.alloy_daily_snapshot_env_services[count.index].job_name
      state    = "SUCCEEDED"
    }
  }
}

resource "aws_glue_crawler" "alloy_snapshot" {
  count = local.is_live_environment ? length(local.alloy_queries) : 0
  tags  = module.tags.values

  database_name = module.department_environmental_services_data_source.refined_zone_catalog_database_name
  name          = "${local.short_identifier_prefix}Alloy Snapshot ${local.alloy_query_names[count.index]}"
  role          = module.department_environmental_services_data_source.glue_role_arn

  s3_target {
    path = "s3://${module.refined_zone_data_source.bucket_id}/env-services/alloy/snapshots/"
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 5
    }
  })
}
