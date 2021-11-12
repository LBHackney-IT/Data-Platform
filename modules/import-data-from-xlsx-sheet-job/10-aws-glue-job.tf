# Import test data
module "xlsx_import" {
  source = "../aws-glue-job"

  department = var.department
  job_name   = "Xlsx Import Job - ${var.glue_job_name}"
  job_parameters = {
    "--s3_bucket_source"  = "s3://${var.landing_zone_bucket_id}/${var.department.identifier}/${var.input_file_name}"
    "--s3_bucket_target"  = local.s3_output_path
    "--header_row_number" = var.header_row_number
    "--TempDir"           = "s3://${var.glue_temp_storage_bucket_id}/${var.department.identifier}/"
    "--worksheet_name"    = var.worksheet_name
    "--extra-py-files"    = "s3://${var.glue_scripts_bucket_id}/${var.helpers_script_key}"
    "--extra-jars"        = "s3://${var.glue_scripts_bucket_id}/${var.jars_key}"
  }
  script_name            = var.xlsx_import_script_key
  workflow_name          = aws_glue_workflow.workflow.name
  glue_scripts_bucket_id = var.glue_scripts_bucket_id
  crawler_details = {
    table_prefix       = "${var.department.identifier_snake_case}_"
    database_name      = var.glue_catalog_database_name
    s3_target_location = local.s3_output_path
  }
}

resource "aws_glue_workflow" "workflow" {
  name = "${var.identifier_prefix}${local.import_name}"
}



