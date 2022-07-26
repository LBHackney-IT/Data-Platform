module "import_file_from_g_drive_data_source" {
  source            = "../g-drive-to-s3"
  identifier_prefix = var.identifier_prefix
  lambda_name       = lower(replace(var.glue_job_name, "/[^a-zA-Z0-9]+/", "-"))
}

module "import_data_from_spreadsheet_job_data_source" {
  for_each = var.worksheets

  source                        = "../import-data-from-spreadsheet-job"
  is_production_environment     = var.is_production_environment
  is_live_environment           = var.is_live_environment
  department                    = var.department
  glue_catalog_database_name    = var.glue_catalog_database_name
  spreadsheet_import_script_key = var.spreadsheet_import_script_key
  glue_job_name                 = "${var.identifier_prefix}${var.glue_job_name} - ${each.value.worksheet_name}"
  output_folder_name            = var.output_folder_name
  data_set_name                 = lower(replace(replace(replace(trimspace(each.value.worksheet_name), ".", ""), "/[^a-zA-Z0-9]+/", "-"), "/-+/", "-"))
  raw_zone_bucket_id            = var.raw_zone_bucket_id
  worksheet_name                = each.value.worksheet_name
  identifier_prefix             = var.identifier_prefix
}
