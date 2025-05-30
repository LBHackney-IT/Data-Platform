# Import test data

module "google_sheet_import" {
  source                    = "../aws-glue-job"
  is_live_environment       = var.is_live_environment
  is_production_environment = var.is_production_environment

  department                 = var.department
  job_name                   = "Google Sheets Import Job - ${local.import_name}"
  helper_module_key          = var.helper_module_key
  pydeequ_zip_key            = var.pydeequ_zip_key
  script_s3_object_key       = var.google_sheets_import_script_key
  spark_ui_output_storage_id = var.spark_ui_output_storage_id

  job_parameters = {
    "--additional-python-modules" = "gspread==3.7.0, google-auth==2.13.0, pyspark==3.1.1"
    "--document_key"              = var.google_sheets_document_id
    "--worksheet_name"            = var.google_sheets_worksheet_name
    "--header_row_number"         = var.google_sheet_header_row_number
    "--secret_id"                 = local.sheets_credentials_name
    "--s3_bucket_target"          = local.full_output_path
  }
  workflow_name   = var.create_workflow ? aws_glue_workflow.workflow[0].name : null
  schedule        = var.google_sheet_import_schedule
  max_retries     = var.max_retries
  trigger_enabled = (var.is_live_environment && var.enable_glue_trigger)
}

resource "aws_glue_workflow" "workflow" {
  count = var.create_workflow ? 1 : 0
  name  = "${var.identifier_prefix}${local.import_name}"
  tags  = var.tags
}
