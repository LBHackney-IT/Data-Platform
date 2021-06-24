# Import test data
resource "aws_glue_job" "xlsx_import" {
  tags = var.tags

  name              = "Xlsx Import Job - ${var.glue_job_name}"
  number_of_workers = 10
  worker_type       = "G.1X"
  role_arn          = var.glue_role_arn
  command {
    python_version  = "3"
    script_location = "s3://${var.glue_scripts_bucket_id}/${var.xlsx_import_script_key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--s3_bucket_source"          = "s3://${var.raw_zone_bucket_id}/${var.department_folder_name}/${var.input_file_name}"
    "--additional-python-modules" = "openpyxl"
    "--s3_bucket_target"          = "s3://${var.landing_zone_bucket_id}/${var.department_folder_name}/${var.output_folder_name}"
    "--header_row_number"         = var.header_row_number
    "--TempDir"                   = "s3://${var.glue_temp_storage_bucket_id}"
    "--additional-python-modules" = "gspread==3.7.0, google-auth==1.27.1, pyspark==3.1.1"
    "--document_key"              = var.google_sheets_document_id
    "--worksheet_name"            = var.google_sheets_worksheet_name
    "--secret_id"                 = var.sheets_credentials_name
    "--worksheet_name"            = var.worksheet_name
  }
}

resource "aws_glue_trigger" "google_sheet_import_trigger" {
  name     = "Xlsx Import Job Glue Trigger- ${var.glue_job_name}"
  schedule = var.xlsx_import_schedule
  type     = "SCHEDULED"
  enabled  = var.enable_glue_trigger

  actions {
    job_name = aws_glue_job.xlsx_import.name
  }
}
