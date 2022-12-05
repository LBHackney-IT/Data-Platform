locals {
  # These values already exist in terraform\etl\25-aws-glue-job-env-services.tf
  #alloy_queries                     = local.is_live_environment ? fileset("${path.module}/../../scripts/jobs/env_services/aqs", "*json") : []
  #alloy_queries_max_concurrent_runs = local.is_live_environment ? length(local.alloy_queries) : 1
  alloy_query_names_alphanumeric = local.is_live_environment ? [for i in local.alloy_query_names : replace(i, "\\W", "_")] : []
}

resource "aws_glue_trigger" "alloy_daily_export" {
  count   = local.is_live_environment ? length(local.alloy_queries) : 0
  tags    = module.tags.values
  enabled = local.is_production_environment

  name     = "${local.short_identifier_prefix} Alloy API Export Job Trigger ${local.alloy_query_names_alphanumeric[count.index]}"
  type     = "SCHEDULED"
  schedule = "cron(0 3 ? * MON-FRI *)"

  actions {
    job_name = module.alloy_api_export_raw_env_services[count.index].job_name
  }

  timeouts {
    delete = "15m"
  }
}

module "alloy_api_export_raw_env_services" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment
  count                     = local.is_live_environment ? length(local.alloy_queries) : 0

  job_description = "This job queries the Alloy API and saves the exported csvs to s3"
  department      = module.department_environmental_services_data_source
  job_name        = "${local.short_identifier_prefix}_alloy_api_export_${local.alloy_query_names_alphanumeric[count.index]}_env_services"

  helper_module_key          = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key            = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  trigger_enabled            = false
  script_name                = "alloy_api_export"
  job_parameters = {
    "--job-bookmark-option"     = "job-bookmark-enable"
    "--enable-glue-datacatalog" = "true"
    "--secret_name"             = "${local.identifier_prefix}/env-services/alloy-api-key"
    "--aqs"                     = file("${path.module}/../../scripts/jobs/env_services/aqs/${tolist(local.alloy_queries)[count.index]}")
    "--s3_raw_zone_bucket"      = module.raw_zone_data_source.bucket_id
    "--s3_downloads_prefix"     = "env-services/alloy/alloy_api_downloads/${local.alloy_query_names_alphanumeric[count.index]}/"
    "--s3_parquet_prefix"       = "env-services/alloy/parquet_files/${local.alloy_query_names_alphanumeric[count.index]}/"
    "--prefix_to_remove"        = "joineddesign_"
  }
}



resource "aws_glue_trigger" "alloy_export_crawler" {
  count   = local.is_live_environment ? length(local.alloy_queries) : 0
  tags    = module.tags.values
  name    = "${local.short_identifier_prefix} Alloy Export Crawler ${local.alloy_query_names_alphanumeric[count.index]}"
  type    = "CONDITIONAL"
  enabled = local.is_production_environment

  actions {
    crawler_name = aws_glue_crawler.alloy_export_crawler[count.index].name
  }

  predicate {
    conditions {
      job_name = module.alloy_api_export_raw_env_services[count.index].job_name
      state    = "SUCCEEDED"
    }
  }

  timeouts {
    delete = "15m"
  }
}

resource "aws_glue_crawler" "alloy_export_crawler" {
  count = local.is_live_environment ? length(local.alloy_queries) : 0
  tags  = module.tags.values

  database_name = module.department_environmental_services_data_source.raw_zone_catalog_database_name
  name          = "${local.short_identifier_prefix} Alloy Export Crawler ${local.alloy_query_names_alphanumeric[count.index]}"
  role          = module.department_environmental_services_data_source.glue_role_arn

  s3_target {
    path = "s3://${module.raw_zone_data_source.bucket_id}/env-services/alloy/parquet_files/${local.alloy_query_names_alphanumeric[count.index]}/"
  }
  table_prefix = "${lower(local.alloy_query_names_alphanumeric[count.index])}_"

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 6
    }
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
    }
    }
  )
  schema_change_policy {
    update_behavior = "LOG"
  }
}

module "alloy_raw_to_refined_env_services" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment
  count                     = local.is_live_environment ? length(local.alloy_queries) : 0

  job_description = "This job transforms the daily csv exports and saves them to the refined zone"
  department      = module.department_environmental_services_data_source
  job_name        = "${local.short_identifier_prefix}_${local.alloy_query_names_alphanumeric[count.index]}_alloy_daily_raw_to_refined_env_services"

  helper_module_key          = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key            = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  triggered_by_crawler       = aws_glue_crawler.alloy_export_crawler[count.index].name
  script_name                = "alloy_raw_to_refined"
  job_parameters = {
    "--job-bookmark-option"     = "job-bookmark-enable"
    "--enable-glue-datacatalog" = "true"
    "--glue_database"           = "env-services-raw-zone"
    "--glue_table_prefix"       = "${lower(local.alloy_query_names_alphanumeric[count.index])}_"
    "--s3_refined_zone_bucket"  = module.refined_zone_data_source.bucket_id
    "--s3_mapping_bucket"       = module.raw_zone_data_source.bucket_id
    "--s3_mapping_location"     = "/env-services/alloy/mapping-files/"
    "--s3_target_prefix"        = "env-services/alloy/${local.alloy_query_names_alphanumeric[count.index]}/"
  }
}

resource "aws_glue_trigger" "alloy_refined_crawler" {
  count   = local.is_live_environment ? length(local.alloy_queries) : 0
  tags    = module.tags.values
  name    = "${local.short_identifier_prefix} Alloy Refined Crawler ${local.alloy_query_names_alphanumeric[count.index]}"
  type    = "CONDITIONAL"
  enabled = local.is_production_environment

  actions {
    crawler_name = aws_glue_crawler.alloy_refined[count.index].name
  }

  predicate {
    conditions {
      job_name = module.alloy_raw_to_refined_env_services[count.index].job_name
      state    = "SUCCEEDED"
    }
  }

  timeouts {
    delete = "15m"
  }
}

resource "aws_glue_crawler" "alloy_refined" {
  count = local.is_live_environment ? length(local.alloy_queries) : 0
  tags  = module.tags.values

  database_name = module.department_environmental_services_data_source.refined_zone_catalog_database_name
  name          = "${local.short_identifier_prefix} Alloy Refined Crawler ${local.alloy_query_names_alphanumeric[count.index]}"
  role          = module.department_environmental_services_data_source.glue_role_arn

  s3_target {
    path = "s3://${module.refined_zone_data_source.bucket_id}/env-services/alloy/${local.alloy_query_names_alphanumeric[count.index]}"
  }
  table_prefix = "alloy_"
  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 5
    }
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
      Tables     = { AddOrUpdateBehavior = "MergeNewColumns" }
    }
  })

}
