# Import test data
module "spreadsheet_import" {
  source                    = "../aws-glue-job"
  is_live_environment       = var.is_live_environment
  is_production_environment = var.is_production_environment

  department        = var.department
  job_name          = "Spreadsheet Import Job - ${var.department.identifier}-${var.glue_job_name}"
  helper_module_key = var.helper_module_key
  pydeequ_zip_key   = var.pydeequ_zip_key
  glue_role_arn     = var.glue_role_arn
  job_parameters = {
    "--s3_bucket_source"    = "s3://${var.landing_zone_bucket_id}/${var.department.identifier}/${var.output_folder_name}/${var.input_file_name}"
    "--s3_bucket_target"    = "s3://${var.raw_zone_bucket_id}/${var.department.identifier}/${var.output_folder_name}/${var.data_set_name}"
    "--header_row_number"   = var.header_row_number
    "--worksheet_name"      = var.worksheet_name
    "--job_bookmark_option" = local.job_bookmark_option
  }
  script_s3_object_key       = var.spreadsheet_import_script_key
  spark_ui_output_storage_id = var.spark_ui_output_storage_id
  extra_jars                 = ["s3://${var.department.glue_scripts_bucket.bucket_id}/${var.jars_key}"]
  workflow_name              = aws_glue_workflow.workflow.name
  crawler_details = {
    database_name      = var.glue_catalog_database_name
    s3_target_location = "s3://${var.raw_zone_bucket_id}/${var.department.identifier}/${var.output_folder_name}"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableLevelConfiguration = 3
      }
    })
  }
  trigger_enabled = false
}

resource "aws_glue_workflow" "workflow" {
  name = "${var.identifier_prefix}${local.import_name}-${var.output_folder_name}"
}
