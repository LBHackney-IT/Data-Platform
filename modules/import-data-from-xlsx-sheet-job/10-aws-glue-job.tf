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
    "--s3_bucket_source"          = "s3://${var.landing_zone_bucket_id}/${var.department_folder_name}/${var.input_file_name}"
    "--additional-python-modules" = "openpyxl"
    "--s3_bucket_target"          = "s3://${var.raw_zone_bucket_id}/${var.department_folder_name}/${var.output_folder_name}"
    "--header_row_number"         = var.header_row_number
    "--TempDir"                   = "s3://${var.glue_temp_storage_bucket_id}"
    "--worksheet_name"            = var.worksheet_name
    "--extra-py-files"            = "s3://${var.glue_scripts_bucket_id}/${var.helpers_script_key}"
  }
}

resource "aws_glue_trigger" "xlsx_import_trigger" {
  name     = "Xlsx Import Job Glue Trigger - ${var.glue_job_name}"
  schedule = var.xlsx_import_schedule
  type     = "SCHEDULED"
  enabled  = var.enable_glue_trigger

  actions {
    job_name = aws_glue_job.xlsx_import.name
  }

}
resource "aws_glue_crawler" "xlsx_import" {
  tags = var.tags

  database_name = var.glue_catalog_database_name
  name          = "${var.raw_zone_bucket_id}-${var.department_folder_name}-${var.worksheet_name}"
  role          = var.glue_role_arn
  table_prefix  = "${replace(var.department_folder_name, "-", "_")}_"

  s3_target {
    path = "s3://${var.raw_zone_bucket_id}/${var.department_folder_name}/${var.output_folder_name}"
  }
}

resource "aws_glue_trigger" "xlsx_import_crawler_trigger" {
  tags = var.tags

  name    = "Xlsx Crawler Trigger - ${var.glue_job_name}"
  type    = "CONDITIONAL"
  enabled = true

  predicate {
    conditions {
      state    = "SUCCEEDED"
      job_name = aws_glue_job.xlsx_import.name
    }
  }

  actions {
    job_name = aws_glue_crawler.xlsx_import.name
  }
}
