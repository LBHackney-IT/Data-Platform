module "repairs_dlo" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  helper_module_key               = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_repairs.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  google_sheets_document_id       = "1i9q42Kkbugwi4f2S4zdyid2ZjoN1XLjuYvqYqfHyygs"
  google_sheets_worksheet_name    = "Form responses 1"
  department                      = module.department_housing_repairs
  dataset_name                    = "repairs-dlo"
  enable_glue_trigger             = false
}

module "repairs_herts_heritage" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  helper_module_key               = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_repairs.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  google_sheets_document_id       = "1Psw8i2qooASPLjaBfGKNX7upiX7BeQSiMeJ8dQngSJI"
  google_sheets_worksheet_name    = "Form responses 1"
  department                      = module.department_housing_repairs
  dataset_name                    = "repairs-herts-heritage"
  enable_glue_trigger             = false
}

module "repairs_avonline" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  helper_module_key               = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_repairs.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  google_sheets_document_id       = "1nM99bPaOPvg5o_cz9_yJR6jlnMB0oSHdFhAMKQkPJi4"
  google_sheets_worksheet_name    = "Form responses 1"
  department                      = module.department_housing_repairs
  dataset_name                    = "repairs-avonline"
  enable_glue_trigger             = false
}

module "repairs_alpha_track" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  helper_module_key               = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_repairs.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  google_sheets_document_id       = "1cbeVvMuNNinVQDeVfsUWalRpY6zK9oZPa3ebLtLSiAc"
  google_sheets_worksheet_name    = "Form responses 1"
  department                      = module.department_housing_repairs
  dataset_name                    = "repairs-alpha-track"
  enable_glue_trigger             = false
}

module "repairs_stannah" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  helper_module_key               = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_repairs.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  google_sheets_document_id       = "1CpC_Dn4aM8MSFb5a6HJ_FEsVYcahRsis9YIATcfArhw"
  google_sheets_worksheet_name    = "Form responses 1"
  department                      = module.department_housing_repairs
  dataset_name                    = "repairs-stannah"
  enable_glue_trigger             = false
}

module "repairs_purdy" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  helper_module_key               = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_repairs.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  google_sheets_document_id       = "1-PpKPnaPMA6AogsNXT5seqQk3VUB-naFnFJYhROkl2o"
  google_sheets_worksheet_name    = "FormresponsesPUR"
  department                      = module.department_housing_repairs
  dataset_name                    = "repairs-purdy"
  enable_glue_trigger             = false
}

module "repairs_axis" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  helper_module_key               = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_repairs.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  google_sheets_document_id       = "1aDWO9ZAVar377jiYTXkZzDCIckCqbhppOW23B85hFsA"
  google_sheets_worksheet_name    = "Form responses 1"
  department                      = module.department_housing_repairs
  dataset_name                    = "repairs-axis"
  enable_glue_trigger             = false
}

module "parking_spreadsheet_estate_permit_limits" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  helper_module_key               = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_parking.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone.bucket_id
  google_sheets_document_id       = "14H-kO4wB011ol7J7hLSJ9xv56R4xugmGsZCWNMbe1Ys"
  google_sheets_worksheet_name    = "Import into Qlik Inline Load"
  department                      = module.department_parking
  dataset_name                    = "estate_permit_limits"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
}

module "parking_spreadsheet_parkmap_restrictions_report" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  helper_module_key               = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_parking.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone.bucket_id
  google_sheets_document_id       = "14Ago8grVd-tW7N0aSlcNZoxzsLDViSYys4shw1wLRno"
  google_sheets_worksheet_name    = "6th June 2019"
  department                      = module.department_parking
  dataset_name                    = "parkmap_restrictions_report"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
}

module "sandbox_daro_covid_locations" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  helper_module_key               = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone.bucket_id
  google_sheets_document_id       = "1-ZNoQGu0LGlaKYDBWD8MUo8hqfcnE5YbgCXVz2MUxSw"
  google_sheets_worksheet_name    = "locations"
  department                      = module.department_sandbox
  dataset_name                    = "daro_covid_locations"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
}

module "sandbox_daro_covid_vaccinations" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  helper_module_key               = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone.bucket_id
  google_sheets_document_id       = "1-ZNoQGu0LGlaKYDBWD8MUo8hqfcnE5YbgCXVz2MUxSw"
  google_sheets_worksheet_name    = "vaccinations"
  department                      = module.department_sandbox
  dataset_name                    = "daro_covid_vaccinations"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
}
    
  module "covid_locations_lisa" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  helper_module_key               = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_sandbox.name
  google_sheets_document_id       = "187SSANhwBF1SBL8EMG9YMEYcImZDZ4qHdSYlbmwQsjU"
  google_sheets_worksheet_name    = "locations"
  department                      = module.department_sandbox
  dataset_name                    = "covid-locations-lisa"
  enable_glue_trigger             = false
}
    
      module "covid_vaccinations_lisa" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  helper_module_key               = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_sandbox.name
  google_sheets_document_id       = "187SSANhwBF1SBL8EMG9YMEYcImZDZ4qHdSYlbmwQsjU"
  google_sheets_worksheet_name    = "vaccinations"
  department                      = module.department_sandbox
  dataset_name                    = "covid-vaccinations-lisa"
  enable_glue_trigger             = false
}
