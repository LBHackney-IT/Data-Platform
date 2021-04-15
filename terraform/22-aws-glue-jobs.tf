module "test_data" {
  source = "../modules/google-sheets-glue-job"
  glue_role_arn = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id = aws_s3_bucket.glue_scripts_bucket.id
  glue_temp_storage_bucket_id = aws_s3_bucket.glue_temp_storage_bucket.id
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  landing_zone_bucket_id = module.landing_zone.bucket_id
  sheets_credentials_name = aws_secretsmanager_secret.sheets_credentials_housing.name
  tags = module.tags.values
  glue_job_name = "Test"
  google_sheets_document_id = "1yKAxzUGeGJulFEcVBxatow3jUdTeqfzGvvCgdshiN5g"
  google_sheets_worksheet_name = "Sheet1"
  department_folder_name = "test"
  output_folder_name = "test1"
}

module "housing_repair_data" {
  source = "../modules/google-sheets-glue-job"
  glue_role_arn = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id = aws_s3_bucket.glue_scripts_bucket.id
  glue_temp_storage_bucket_id = aws_s3_bucket.glue_temp_storage_bucket.id
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  landing_zone_bucket_id = module.landing_zone.bucket_id
  sheets_credentials_name = aws_secretsmanager_secret.sheets_credentials_housing.name
  tags = module.tags.values
  glue_job_name = "Repair Orders"
  google_sheets_document_id = "1i9q42Kkbugwi4f2S4zdyid2ZjoN1XLjuYvqYqfHyygs"
  google_sheets_worksheet_name = "Form responses 1"
  department_folder_name = "housing"
  output_folder_name = "repair-orders"
}
