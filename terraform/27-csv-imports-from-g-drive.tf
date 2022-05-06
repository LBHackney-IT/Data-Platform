module "ryan_test_csv" {
  count = local.is_live_environment ? 1 : 1

  source                         = "../modules/import-xlsx-file-from-g-drive"
  department                     = module.department_housing_repairs
  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
  glue_catalog_database_name     = module.department_housing_repairs.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage.bucket_id
  glue_role_arn                  = aws_iam_role.glue_role.arn
  helper_module_key              = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
  jars_key                       = aws_s3_bucket_object.jars.key
  xlsx_import_script_key         = aws_s3_bucket_object.xlsx_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
  landing_zone_bucket_id         = module.landing_zone.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone.bucket_arn
  google_sheets_document_id      = "1m79z2nu-_KSCeUqIKWDmMfohcwdSbc-N"
  glue_job_name                  = "Ryan Test CSV"
  output_folder_name             = "ryan-test-csv"
  raw_zone_bucket_id             = module.raw_zone.bucket_id
  input_file_name                = "Book1.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 1
      worksheet_name    = "Book1"
    }
  }
}
