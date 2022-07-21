module "import_file_from_g_drive" {
  source                                    = "../g-drive-to-s3"
  tags                                      = var.tags
  identifier_prefix                         = var.identifier_prefix
  department_identifier                     = var.department.identifier
  lambda_artefact_storage_bucket            = var.lambda_artefact_storage_bucket
  zone_kms_key_arn                          = var.landing_zone_kms_key_arn
  zone_bucket_arn                           = var.landing_zone_bucket_arn
  zone_bucket_id                            = var.landing_zone_bucket_id
  lambda_name                               = lower(replace(var.glue_job_name, "/[^a-zA-Z0-9]+/", "-"))
  service_area                              = var.department.identifier
  file_id                                   = var.google_drive_document_id
  file_name                                 = var.input_file_name
  output_folder_name                        = var.output_folder_name
  google_service_account_credentials_secret = var.department.google_service_account.credentials_secret.arn
  secrets_manager_kms_key                   = var.secrets_manager_kms_key
  workflow_names                            = [for job in module.import_data_from_spreadsheet_job : job.workflow_name]
  workflow_arns                             = [for job in module.import_data_from_spreadsheet_job : job.workflow_arn]
  ingestion_schedule                        = var.ingestion_schedule
  ingestion_schedule_enabled                = var.is_production_environment || !var.is_live_environment
}

module "import_data_from_spreadsheet_job" {
  for_each = var.worksheets

  source                         = "../import-data-from-spreadsheet-job"
  is_production_environment      = var.is_production_environment
  is_live_environment            = var.is_live_environment
  department                     = var.department
  glue_scripts_bucket_id         = var.glue_scripts_bucket_id
  glue_temp_storage_bucket_id    = var.glue_temp_storage_bucket_id
  glue_catalog_database_name     = var.glue_catalog_database_name
  glue_role_arn                  = var.glue_role_arn
  helper_module_key              = var.helper_module_key
  pydeequ_zip_key                = var.pydeequ_zip_key
  jars_key                       = var.jars_key
  spreadsheet_import_script_key  = var.spreadsheet_import_script_key
  lambda_artefact_storage_bucket = var.lambda_artefact_storage_bucket
  landing_zone_bucket_id         = var.landing_zone_bucket_id
  glue_job_name                  = "${var.identifier_prefix}${var.glue_job_name} - ${each.value.worksheet_name}"
  output_folder_name             = var.output_folder_name
  data_set_name                  = local.is_csv ? var.worksheets.sheet1.worksheet_name : lower(replace(replace(replace(trimspace(each.value.worksheet_name), ".", ""), "/[^a-zA-Z0-9]+/", "-"), "/-+/", "-"))
  raw_zone_bucket_id             = var.raw_zone_bucket_id
  input_file_name                = var.input_file_name
  header_row_number              = each.value.header_row_number
  worksheet_name                 = each.value.worksheet_name
  identifier_prefix              = var.identifier_prefix
  spark_ui_output_storage_id     = var.spark_ui_output_storage_id
  enable_bookmarking             = var.enable_bookmarking
}
