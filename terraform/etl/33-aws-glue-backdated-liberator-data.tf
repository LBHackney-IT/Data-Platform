locals {
  backdated_workflow_name = "${local.short_identifier_prefix}parking-liberator-backdated-data-workflow"
}

resource "aws_glue_trigger" "parking_liberator_backdated_data_workflow_trigger" {
  name          = "${local.short_identifier_prefix}parking-liberator-backdated-workflow-trigger"
  type          = "ON_DEMAND"
  tags          = module.tags.values
  workflow_name = local.backdated_workflow_name

  actions {
    crawler_name = "${local.identifier_prefix}-landing-zone-liberator-backdated"
  }
}

resource "aws_glue_crawler" "landing_zone_liberator_backdated" {
  tags = module.tags.values

  database_name = aws_glue_catalog_database.landing_zone_liberator.name
  name          = "${local.identifier_prefix}-landing-zone-liberator-backdated"
  role          = data.aws_iam_role.glue_role.arn

  s3_target {
    path       = "s3://${module.landing_zone_data_source.bucket_id}/parking/liberator"
    exclusions = local.glue_crawler_excluded_blobs
  }
}

resource "aws_glue_trigger" "parking_liberator_backdated_data_job_trigger" {
  name          = "${local.short_identifier_prefix}parking-liberator-backdated-copy-job-trigger"
  type          = "CONDITIONAL"
  tags          = module.tags.values
  workflow_name = local.backdated_workflow_name

  actions {
    job_name = aws_glue_job.copy_parking_liberator_landing_to_raw_backdated.name
  }

  actions {
    job_name = aws_glue_job.copy_env_enforcement_liberator_landing_to_raw_backdated.name
  }

  predicate {
    conditions {
      crawler_name = aws_glue_crawler.landing_zone_liberator_backdated.name
      crawl_state  = "SUCCEEDED"
    }
  }
}

resource "aws_glue_job" "copy_parking_liberator_landing_to_raw_backdated" {
  tags = module.tags.values

  name              = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw backdated"
  number_of_workers = 10
  worker_type       = "G.1X"

  role_arn = data.aws_iam_role.glue_role.arn
  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts_data_source.bucket_id}/${aws_s3_object.copy_tables_landing_to_raw_backdated.key}"
  }

  glue_version = "4.0"

  default_arguments = {
    "--job-bookmark-option"       = "job-bookmark-enable"
    "--s3_bucket_target"          = module.raw_zone_data_source.bucket_id
    "--s3_prefix"                 = "parking/liberator/"
    "--table_filter_expression"   = "^liberator_(?!fpn).*"
    "--glue_database_name_source" = aws_glue_catalog_database.landing_zone_liberator.name
    "--glue_database_name_target" = aws_glue_catalog_database.raw_zone_liberator.name
    "--extra-py-files"            = "s3://${module.glue_scripts_data_source.bucket_id}/${data.aws_s3_object.helpers.key}"
    "--enable-glue-datacatalog"   = "true"
    "--enable-spark-ui"           = "true"
    "--spark-event-logs-path"     = "s3://${module.spark_ui_output_storage_data_source.bucket_id}/parking/liberator/"
  }
}

resource "aws_glue_job" "copy_env_enforcement_liberator_landing_to_raw_backdated" {
  tags = module.tags.values

  name              = "${local.short_identifier_prefix}Copy Env Enforcement Liberator landing zone to raw backdated"
  number_of_workers = 2
  worker_type       = "G.1X"
  role_arn          = data.aws_iam_role.glue_role.arn
  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts_data_source.bucket_id}/${aws_s3_object.copy_tables_landing_to_raw_backdated.key}"
  }

  glue_version = "4.0"

  default_arguments = {
    "--job-bookmark-option"       = "job-bookmark-enable"
    "--s3_bucket_target"          = module.raw_zone_data_source.bucket_id
    "--s3_prefix"                 = "env-enforcement/liberator/"
    "--table_filter_expression"   = "^liberator_fpn.*"
    "--glue_database_name_source" = aws_glue_catalog_database.landing_zone_liberator.name
    "--glue_database_name_target" = module.department_env_enforcement_data_source.raw_zone_catalog_database_name
    "--extra-py-files"            = "s3://${module.glue_scripts_data_source.bucket_id}/${data.aws_s3_object.helpers.key}"
    "--enable-glue-datacatalog"   = "true"
    "--enable-spark-ui"           = "true"
    "--spark-event-logs-path"     = "s3://${module.spark_ui_output_storage_data_source.bucket_id}/env-enforcement/liberator/"
  }
}
