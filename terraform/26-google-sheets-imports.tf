module "repairs_dlo" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  helpers_script_key              = aws_s3_bucket_object.helpers.key
  glue_catalog_database_name      = module.department_housing_repairs.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id     = module.glue_temp_storage.bucket_id
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  tags                            = module.department_housing_repairs.tags
  google_sheets_document_id       = "1i9q42Kkbugwi4f2S4zdyid2ZjoN1XLjuYvqYqfHyygs"
  google_sheets_worksheet_name    = "Form responses 1"
  department_name                 = "housing-repairs"
  dataset_name                    = "repairs-dlo"
}

module "repairs_herts_heritage" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  helpers_script_key              = aws_s3_bucket_object.helpers.key
  glue_catalog_database_name      = module.department_housing_repairs.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id     = module.glue_temp_storage.bucket_id
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  tags                            = module.department_housing_repairs.tags
  google_sheets_document_id       = "1Psw8i2qooASPLjaBfGKNX7upiX7BeQSiMeJ8dQngSJI"
  google_sheets_worksheet_name    = "Form responses 1"
  department_name                 = "housing-repairs"
  dataset_name                    = "repairs-herts-heritage"
}

module "repairs_avonline" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  helpers_script_key              = aws_s3_bucket_object.helpers.key
  glue_catalog_database_name      = module.department_housing_repairs.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id     = module.glue_temp_storage.bucket_id
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  tags                            = module.department_housing_repairs.tags
  google_sheets_document_id       = "1nM99bPaOPvg5o_cz9_yJR6jlnMB0oSHdFhAMKQkPJi4"
  google_sheets_worksheet_name    = "Form responses 1"
  department_name                 = "housing-repairs"
  dataset_name                    = "repairs-avonline"
}

module "repairs_alpha_track" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  helpers_script_key              = aws_s3_bucket_object.helpers.key
  glue_catalog_database_name      = module.department_housing_repairs.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id     = module.glue_temp_storage.bucket_id
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  tags                            = module.department_housing_repairs.tags
  google_sheets_document_id       = "1cbeVvMuNNinVQDeVfsUWalRpY6zK9oZPa3ebLtLSiAc"
  google_sheets_worksheet_name    = "Form responses 1"
  department_name                 = "housing-repairs"
  dataset_name                    = "repairs-alpha-track"
}

module "repairs_stannah" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  helpers_script_key              = aws_s3_bucket_object.helpers.key
  glue_catalog_database_name      = module.department_housing_repairs.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id     = module.glue_temp_storage.bucket_id
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  tags                            = module.department_housing_repairs.tags
  google_sheets_document_id       = "1CpC_Dn4aM8MSFb5a6HJ_FEsVYcahRsis9YIATcfArhw"
  google_sheets_worksheet_name    = "Form responses 1"
  department_name                 = "housing-repairs"
  dataset_name                    = "repairs-stannah"
}

module "repairs_purdy" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  helpers_script_key              = aws_s3_bucket_object.helpers.key
  glue_catalog_database_name      = module.department_housing_repairs.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id     = module.glue_temp_storage.bucket_id
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  tags                            = module.department_housing_repairs.tags
  google_sheets_document_id       = "1-PpKPnaPMA6AogsNXT5seqQk3VUB-naFnFJYhROkl2o"
  google_sheets_worksheet_name    = "FormresponsesPUR"
  department_name                 = "housing-repairs"
  dataset_name                    = "repairs-purdy"
}

module "repairs_axis" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  helpers_script_key              = aws_s3_bucket_object.helpers.key
  glue_catalog_database_name      = module.department_housing_repairs.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id     = module.glue_temp_storage.bucket_id
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  tags                            = module.department_housing_repairs.tags
  google_sheets_document_id       = "1aDWO9ZAVar377jiYTXkZzDCIckCqbhppOW23B85hFsA"
  google_sheets_worksheet_name    = "Form responses 1"
  department_name                 = "housing-repairs"
  dataset_name                    = "repairs-axis"
}

module "parking_spreadsheet_estate_permit_limits" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_role_arn                   = module.department_parking.glue_role_arn
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  helpers_script_key              = aws_s3_bucket_object.helpers.key
  glue_catalog_database_name      = module.department_parking.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id     = module.glue_temp_storage.bucket_id
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone.bucket_id
  sheets_credentials_name         = module.department_parking.google_service_account.credentials_secret.name
  tags                            = module.department_parking.tags
  google_sheets_document_id       = "14H-kO4wB011ol7J7hLSJ9xv56R4xugmGsZCWNMbe1Ys"
  google_sheets_worksheet_name    = "Import into Qlik Inline Load"
  department_name                 = "parking"
  dataset_name                    = "estate_permit_limits"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
}

module "parking_spreadsheet_parkmap_restrictions_report" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_role_arn                   = module.department_parking.glue_role_arn
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  helpers_script_key              = aws_s3_bucket_object.helpers.key
  glue_catalog_database_name      = module.department_parking.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id     = module.glue_temp_storage.bucket_id
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone.bucket_id
  sheets_credentials_name         = module.department_parking.google_service_account.credentials_secret.name
  tags                            = module.department_parking.tags
  google_sheets_document_id       = "14Ago8grVd-tW7N0aSlcNZoxzsLDViSYys4shw1wLRno"
  google_sheets_worksheet_name    = "6th June 2019"
  department_name                 = "parking"
  dataset_name                    = "parkmap_restrictions_report"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
}

module "dni_david_testing" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  helpers_script_key              = aws_s3_bucket_object.helpers.key
  glue_catalog_database_name      = module.department_data_and_insight.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id     = module.glue_temp_storage.bucket_id
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone.bucket_id
  sheets_credentials_name         = module.department_data_and_insight.google_service_account.credentials_secret.name
  tags                            = module.department_data_and_insight.tags
  google_sheets_document_id       = "1yG_R0j_xcj-N5sznf5lEqFtaV7LIJVLf0Ix-R66-WUQ"
  google_sheets_worksheet_name    = "Sheet1"
  department_name                 = "data-and-insight"
  dataset_name                    = "dni-david-testing"
}
