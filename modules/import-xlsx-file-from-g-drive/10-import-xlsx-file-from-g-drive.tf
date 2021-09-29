module "import_file_from_g_drive" {
  source                         = "../g-drive-to-s3"
  tags                           = var.tags
  identifier_prefix              = var.identifier_prefix
  lambda_artefact_storage_bucket = var.lambda_artefact_storage_bucket
  zone_kms_key_arn               = var.landing_zone_kms_key_arn
  zone_bucket_arn                = var.landing_zone_bucket_arn
  zone_bucket_id                 = var.landing_zone_bucket_id
  lambda_name                    = lower(replace(var.glue_job_name, " ", "-"))
  service_area                   = var.department_folder_name
  file_id                        = var.google_sheets_document_id
  file_name                      = var.input_file_name
  workflow_names                 = [for job in module.import_data_from_xlsx_sheet_job : job.workflow_name]
  workflow_arns                  = [for job in module.import_data_from_xlsx_sheet_job : job.workflow_arn]
}

module "import_data_from_xlsx_sheet_job" {
  for_each = var.worksheets

  source                         = "../import-data-from-xlsx-sheet-job"
  glue_role_arn                  = var.glue_role_arn
  glue_scripts_bucket_id         = var.glue_scripts_bucket_id
  glue_temp_storage_bucket_id    = var.glue_temp_storage_bucket_id
  glue_catalog_database_name     = var.glue_catalog_database_name
  helpers_script_key             = var.helpers_script_key
  jars_key                       = var.jars_key
  xlsx_import_script_key         = var.xlsx_import_script_key
  lambda_artefact_storage_bucket = var.lambda_artefact_storage_bucket
  landing_zone_bucket_id         = var.landing_zone_bucket_id
  tags                           = local.tags_with_department
  glue_job_name                  = "${var.glue_job_name} - ${each.value.worksheet_name}"
  department_folder_name         = var.department_folder_name
  output_folder_name             = var.output_folder_name
  data_set_name                  = lower(replace(replace(replace(trimspace(each.value.worksheet_name), ".", ""), "/[^a-zA-Z0-9]+/", "-"), "/-+/", "-"))
  raw_zone_bucket_id             = var.raw_zone_bucket_id
  input_file_name                = var.input_file_name
  header_row_number              = each.value.header_row_number
  worksheet_name                 = each.value.worksheet_name
  identifier_prefix              = var.identifier_prefix
}
