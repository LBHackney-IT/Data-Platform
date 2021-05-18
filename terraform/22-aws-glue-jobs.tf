module "test_data" {
  count = terraform.workspace == "default" ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  glue_temp_storage_bucket_id     = module.glue_temp_storage.bucket_arn
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  landing_zone_bucket_id          = module.landing_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  tags                            = module.tags.values
  glue_job_name                   = "Repair Orders vJames"
  google_sheets_document_id       = "13PfT9f56g2yQTdyU0wadILeT6L337CTtOHyRAtNuVR8"
  google_sheets_worksheet_name    = "Form responses 1"
  department_folder_name          = "test"
  output_folder_name              = "repair-orders-v2"
  enable_glue_trigger             = false
}

module "housing_repair_data" {
  count = terraform.workspace == "default" ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  glue_temp_storage_bucket_id     = module.glue_temp_storage.bucket_arn
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  landing_zone_bucket_id          = module.landing_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  tags                            = module.tags.values
  glue_job_name                   = "Repair Orders"
  google_sheets_document_id       = "1i9q42Kkbugwi4f2S4zdyid2ZjoN1XLjuYvqYqfHyygs"
  google_sheets_worksheet_name    = "Form responses 1"
  department_folder_name          = "housing"
  output_folder_name              = "repair-orders"
  enable_glue_trigger             = false
}
    
 module "order_form_data" {
  count = terraform.workspace == "default" ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  glue_temp_storage_bucket_id     = module.glue_temp_storage.bucket_arn
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  landing_zone_bucket_id          = module.landing_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  tags                            = module.tags.values
  glue_job_name                   = "Order Form Example"
  google_sheets_document_id       = "1Xc6dcQVQt1ERUjWpfxpRX5QtuSWdsgC6Swtz26VFJfI"
  google_sheets_worksheet_name    = "Form responses 1"
  department_folder_name          = "test"
  output_folder_name              = "order-form"
  enable_glue_trigger             = false
}
    
  module "test-repairs-herts-heritage-data" {
  count = terraform.workspace == "default" ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  glue_temp_storage_bucket_id     = module.glue_temp_storage.bucket_arn
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  landing_zone_bucket_id          = module.landing_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  tags                            = module.tags.values
  glue_job_name                   = "Test Herts Heritage Repairs"
  google_sheets_document_id       = "1GfnEH4OAdmwQYxrYvlSNjoFl6yRgSztf3JlAMdSxU3g"
  google_sheets_worksheet_name    = "Form responses 1"
  department_folder_name          = "housing"
  output_folder_name              = "test-repairs-herts-heritage"
}
