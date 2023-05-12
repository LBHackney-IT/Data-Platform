resource "aws_glue_catalog_database" "parking_raw_zone_manual_catalog_database" {
  count = !local.is_production_environment ? 1 : 0
  name  = "${local.short_identifier_prefix}parking-raw-zone-manual"

  lifecycle {
    prevent_destroy = true
  }
}

module "manually_uploaded_parking_data_to_raw" {
  source = "../modules/aws-glue-job"

  count                      = !local.is_production_environment ? 1 : 0
  is_production_environment  = local.is_production_environment
  is_live_environment        = local.is_live_environment
  department                 = module.department_parking_data_source
  job_name                   = "${local.short_identifier_prefix}Parking Copy Manually Uploaded CSVs to Raw"
  helper_module_key          = data.aws_s3_object.helpers.key
  pydeequ_zip_key            = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-enable"
    "--s3_bucket_target"    = module.raw_zone_data_source.bucket_id
    "--s3_bucket_source"    = module.landing_zone_data_source.bucket_id
    "--s3_prefix"           = "parking/manual/"
    "--extra-py-files"      = "s3://${module.glue_scripts_data_source.bucket_id}/${data.aws_s3_object.helpers.key}"
  }
  script_s3_object_key = aws_s3_object.copy_manually_uploaded_csv_data_to_raw.key
  trigger_enabled      = false
  crawler_details = {
    database_name      = aws_glue_catalog_database.parking_raw_zone_manual_catalog_database[0].name
    s3_target_location = "s3://${module.raw_zone_data_source.bucket_id}/parking/manual/"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableLevelConfiguration = 4
      }
    })
  }
}

resource "aws_glue_crawler" "raw_zone_parking_manual_crawler" {
  count = !local.is_production_environment ? 1 : 0
  tags  = module.department_parking_data_source.tags

  database_name = aws_glue_catalog_database.parking_raw_zone_manual_catalog_database[0].name
  name          = "${local.short_identifier_prefix}raw-zone-parking-manual"
  role          = data.aws_iam_role.glue_role.arn

  s3_target {
    path       = "s3://${module.raw_zone_data_source.bucket_id}/parking/manual"
    exclusions = local.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 4
    }
  })
}

resource "aws_glue_trigger" "raw_zone_parking_manual_spreadsheets_crawler_trigger" {
  count = !local.is_production_environment ? 1 : 0
  tags  = module.department_parking_data_source.tags

  name     = "${local.short_identifier_prefix}parking-raw-manual-crawler-trigger"
  schedule = "cron(0 23 * * ? *)"
  type     = "SCHEDULED"
  enabled  = !local.is_production_environment

  actions {
    crawler_name = aws_glue_crawler.raw_zone_parking_manual_crawler[0].name
  }
}