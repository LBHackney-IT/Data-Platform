# Import test data
module "xlsx_import" {
  source = "../aws-glue-job"

  department        = var.department
  job_name          = "Xlsx Import Job - ${var.glue_job_name}"
  helper_module_key = var.helper_module_key
  pydeequ_zip_key   = var.pydeequ_zip_key
  glue_role_arn     = var.glue_role_arn
  job_parameters = {
    "--s3_bucket_source"  = "s3://${var.landing_zone_bucket_id}/${var.department.identifier}/${var.input_file_name}"
    "--s3_bucket_target"  = local.s3_output_path
    "--header_row_number" = var.header_row_number
    "--worksheet_name"    = var.worksheet_name
  }
  script_s3_object_key       = var.xlsx_import_script_key
  spark_ui_output_storage_id = var.spark_ui_output_storage_id
  extra_jars                 = ["s3://${var.department.glue_scripts_bucket.bucket_id}/${var.jars_key}"]
  workflow_name              = aws_glue_workflow.workflow.name
  crawler_details = {
    table_prefix       = "${var.department.identifier_snake_case}_"
    database_name      = var.glue_catalog_database_name
    s3_target_location = local.s3_output_path
  }
  trigger_enabled = false
}

resource "aws_glue_workflow" "workflow" {
  name = "${var.identifier_prefix}${local.import_name}-${var.output_folder_name}"
}



