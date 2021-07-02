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
  file_id                        = var.google_sheets_import_script_key
  file_name                      = var.input_file_name
}
