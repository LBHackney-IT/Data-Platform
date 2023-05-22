locals {
  s3_object_tags = { for k, v in var.department.tags : k => v if k != "PlatformDepartment" }
  object_key     = "${var.department.identifier_snake_case}/${var.data_cleaning_script_name}.py"
}

resource "aws_s3_bucket_object" "housing_repairs_repairs_cleaning_script" {
  bucket      = var.glue_scripts_bucket_id
  key         = "scripts/${local.object_key}"
  acl         = "private"
  source      = "../../scripts/jobs/${local.object_key}"
  source_hash = filemd5("../../scripts/jobs/${local.object_key}")
}

module "housing_repairs_google_sheets_cleaning" {
  source                    = "../aws-glue-job"
  is_live_environment       = var.is_live_environment
  is_production_environment = var.is_production_environment

  department        = var.department
  job_name          = "${local.glue_job_name} Cleaning"
  helper_module_key = var.helper_module_key
  pydeequ_zip_key   = var.pydeequ_zip_key
  job_parameters = {
    "--source_catalog_database"          = local.raw_zone_catalog_database_name
    "--source_catalog_table"             = var.source_catalog_table
    "--cleaned_repairs_s3_bucket_target" = "s3://${var.refined_zone_bucket_id}/housing-repairs/${var.dataset_name}/cleaned/"
  }
  script_s3_object_key       = aws_s3_bucket_object.housing_repairs_repairs_cleaning_script.key
  spark_ui_output_storage_id = var.spark_ui_output_storage_id
  workflow_name              = var.workflow_name
  triggered_by_crawler       = var.trigger_crawler_name
  crawler_details = {
    table_prefix       = "housing_repairs_${replace(var.dataset_name, "-", "_")}_"
    database_name      = local.refined_zone_catalog_database_name
    s3_target_location = "s3://${var.refined_zone_bucket_id}/housing-repairs/${var.dataset_name}/cleaned/"
    configuration      = null
  }
  trigger_enabled = false
}
