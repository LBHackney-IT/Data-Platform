module "repairs_DLO_data" {
  count                           = terraform.workspace == "default" ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  glue_temp_storage_bucket_id     = module.glue_temp_storage.bucket_arn
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  landing_zone_bucket_id          = module.landing_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  tags                            = module.tags.values
  glue_job_name                   = "DLO Repairs"
  google_sheets_document_id       = "1i9q42Kkbugwi4f2S4zdyid2ZjoN1XLjuYvqYqfHyygs"
  google_sheets_worksheet_name    = "Form responses 1"
  department_folder_name          = "housing"
  output_folder_name              = "repairs-DLO"
}

module "repairs_herts_heritage" {
  count                           = terraform.workspace == "default" ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  glue_temp_storage_bucket_id     = module.glue_temp_storage.bucket_arn
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  landing_zone_bucket_id          = module.landing_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  tags                            = module.tags.values
  glue_job_name                   = "Herts Heritage Repairs"
  google_sheets_document_id       = "1Psw8i2qooASPLjaBfGKNX7upiX7BeQSiMeJ8dQngSJI"
  google_sheets_worksheet_name    = "Form responses 1"
  department_folder_name          = "housing"
  output_folder_name              = "repairs-herts-heritage"
}

module "repairs_avonline" {
  count                           = terraform.workspace == "default" ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  glue_temp_storage_bucket_id     = module.glue_temp_storage.bucket_arn
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  landing_zone_bucket_id          = module.landing_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  tags                            = module.tags.values
  glue_job_name                   = "Avonline Repairs"
  google_sheets_document_id       = "1nM99bPaOPvg5o_cz9_yJR6jlnMB0oSHdFhAMKQkPJi4"
  google_sheets_worksheet_name    = "Form responses 1"
  department_folder_name          = "housing"
  output_folder_name              = "repairs-avonline"
}

module "repairs_alpha_track" {
  count                           = terraform.workspace == "default" ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  glue_temp_storage_bucket_id     = module.glue_temp_storage.bucket_arn
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  landing_zone_bucket_id          = module.landing_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  tags                            = module.tags.values
  glue_job_name                   = "Alpha Track Repairs"
  google_sheets_document_id       = "1cbeVvMuNNinVQDeVfsUWalRpY6zK9oZPa3ebLtLSiAc"
  google_sheets_worksheet_name    = "Form responses 1"
  department_folder_name          = "housing"
  output_folder_name              = "repairs-alpha-track"
}

module "repairs_stannah" {
  count                           = terraform.workspace == "default" ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  glue_temp_storage_bucket_id     = module.glue_temp_storage.bucket_arn
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  landing_zone_bucket_id          = module.landing_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  tags                            = module.tags.values
  glue_job_name                   = "Stannah Repairs"
  google_sheets_document_id       = "1CpC_Dn4aM8MSFb5a6HJ_FEsVYcahRsis9YIATcfArhw"
  google_sheets_worksheet_name    = "Form responses 1"
  department_folder_name          = "housing"
  output_folder_name              = "repairs-stannah"
}

module "test-repairs-purdy-data" {
  count                           = terraform.workspace == "default" ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  glue_temp_storage_bucket_id     = module.glue_temp_storage.bucket_arn
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  landing_zone_bucket_id          = module.landing_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  tags                            = module.tags.values
  glue_job_name                   = "Test Purdy Repair"
  google_sheets_document_id       = "1-PpKPnaPMA6AogsNXT5seqQk3VUB-naFnFJYhROkl2o"
  google_sheets_worksheet_name    = "FormresponsesPUR"
  department_folder_name          = "housing"
  output_folder_name              = "test-repairs-purdy"
}
    
module "test-multiple-headers-in-xlsx" {
  count                           = terraform.workspace == "default" ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  glue_temp_storage_bucket_id     = module.glue_temp_storage.bucket_arn
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  landing_zone_bucket_id          = module.landing_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  tags                            = module.tags.values
  glue_job_name                   = "Testing Multiple Headers in XLSX format"
  google_sheets_document_id       = "1VlM80P6J8N0P3ZeU8VobBP9kMbpr1Lzq"
  google_sheets_worksheet_name    = "Fire Alarm/AOV"
  department_folder_name          = "housing"
  output_folder_name              = "test-repairs-firealarm-aov"
}    

resource "aws_glue_job" "address_matching_glue_job" {
  count = terraform.workspace == "default" ? 1 : 0

  tags = module.tags.values

  name              = "Address Matching"
  number_of_workers = 10
  worker_type       = "G.1X"
  role_arn          = aws_iam_role.glue_role.arn
  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.address_matching.key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--s3_bucket_target"     = "s3://${module.landing_zone.bucket_id}/data-and-insight/address-matching-glue-job-output/"
    "--query_addresses_url"  = "s3://${module.landing_zone.bucket_id}/data-and-insight/address-matching-test/test_addresses.gz.parquet"
    "--target_addresses_url" = "s3://${module.landing_zone.bucket_id}/data-and-insight/address-matching-test/addresses_api_full.gz.parquet"
  }
}
