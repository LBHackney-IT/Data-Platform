# Import test data
resource "aws_glue_job" "google_sheet_import" {
  tags = var.tags

  name              = "Google Sheets Import Job - ${var.glue_job_name}"
  number_of_workers = 10
  worker_type       = "G.1X"
  role_arn          = var.glue_role_arn
  command {
    python_version  = "3"
    script_location = "s3://${var.glue_scripts_bucket_id}/${var.google_sheets_import_script_key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--TempDir"                   = "s3://${var.glue_temp_storage_bucket_id}"
    "--additional-python-modules" = "gspread==3.7.0, google-auth==1.27.1, pyspark==3.1.1"
    "--document_key"              = var.google_sheets_document_id
    "--worksheet_name"            = var.google_sheets_worksheet_name
    "--header_row_number"         = var.google_sheet_header_row_number
    "--secret_id"                 = var.sheets_credentials_name
    "--s3_bucket_target"          = local.full_output_path
    "--extra-py-files"            = "s3://${var.glue_scripts_bucket_id}/${var.helpers_script_key}"
  }
}

resource "aws_glue_crawler" "google_sheet_import" {
  tags = var.tags

  database_name = var.glue_catalog_database_name
  name          = "${var.identifier_prefix}raw-zone-${var.department_name}-${var.dataset_name}"
  role          = var.glue_role_arn
  table_prefix  = "${replace(var.department_name, "-", "_")}_"

  s3_target {
    path       = local.full_output_path
    exclusions = var.glue_crawler_excluded_blobs
  }
}

resource "aws_glue_trigger" "google_sheet_import_schedule" {
  tags = var.tags

  name     = "Google Sheets Import Job Glue Trigger - ${var.glue_job_name}"
  schedule = var.google_sheet_import_schedule
  type     = "SCHEDULED"
  enabled  = (var.is_live_environment && var.enable_glue_trigger)

  actions {
    job_name = aws_glue_job.google_sheet_import.name
  }
}

resource "aws_glue_trigger" "google_sheet_import_crawler_trigger" {
  tags = var.tags

  name    = "Google Sheets Crawler Trigger - ${var.glue_job_name}"
  type    = "CONDITIONAL"
  enabled = true

  predicate {
    conditions {
      state    = "SUCCEEDED"
      job_name = aws_glue_job.google_sheet_import.name
    }
  }

  actions {
    job_name = aws_glue_crawler.google_sheet_import.name
  }
}

//resource "aws_glue_workflow" "google_sheet_import" {
//
//}
