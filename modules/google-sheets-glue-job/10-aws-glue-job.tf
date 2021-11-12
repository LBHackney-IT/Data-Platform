# Import test data

module "google_sheet_import" {
  source = "../aws-glue-job"

  department           = var.department
  job_name             = "Google Sheets Import Job - ${local.import_name}"
  script_s3_object_key = var.google_sheets_import_script_key
  job_parameters = {
    "--additional-python-modules" = "gspread==3.7.0, google-auth==1.27.1, pyspark==3.1.1"
    "--document_key"              = var.google_sheets_document_id
    "--worksheet_name"            = var.google_sheets_worksheet_name
    "--header_row_number"         = var.google_sheet_header_row_number
    "--secret_id"                 = local.sheets_credentials_name
    "--s3_bucket_target"          = local.full_output_path
    "--extra-py-files"            = "s3://${var.glue_scripts_bucket_id}/${var.helpers_script_key}"
  }
  workflow_name   = aws_glue_workflow.workflow.name
  schedule        = var.google_sheet_import_schedule
  trigger_enabled = (var.is_live_environment && var.enable_glue_trigger)
  crawler_details = {
    database_name      = var.glue_catalog_database_name
    s3_target_location = local.full_output_path
    table_prefix       = "${var.department.identifier}_"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableGroupingPolicy = "CombineCompatibleSchemas"
      }
    })
  }
}

resource "aws_glue_workflow" "workflow" {
  name = "${var.identifier_prefix}${local.import_name}"
}
