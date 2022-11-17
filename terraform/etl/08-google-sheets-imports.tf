module "repairs_dlo" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_repairs_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  sheets_credentials_name         = data.aws_ssm_parameter.sheets_credentials_housing_name.value
  google_sheets_document_id       = "1i9q42Kkbugwi4f2S4zdyid2ZjoN1XLjuYvqYqfHyygs"
  google_sheets_worksheet_name    = "Form responses 1"
  department                      = module.department_housing_repairs_data_source
  dataset_name                    = "repairs-dlo"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "repairs_herts_heritage" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_repairs_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  sheets_credentials_name         = data.aws_ssm_parameter.sheets_credentials_housing_name.value
  google_sheets_document_id       = "1Psw8i2qooASPLjaBfGKNX7upiX7BeQSiMeJ8dQngSJI"
  google_sheets_worksheet_name    = "Form responses 1"
  department                      = module.department_housing_repairs_data_source
  dataset_name                    = "repairs-herts-heritage"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "repairs_avonline" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_repairs_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  sheets_credentials_name         = data.aws_ssm_parameter.sheets_credentials_housing_name.value
  google_sheets_document_id       = "1nM99bPaOPvg5o_cz9_yJR6jlnMB0oSHdFhAMKQkPJi4"
  google_sheets_worksheet_name    = "Form responses 1"
  department                      = module.department_housing_repairs_data_source
  dataset_name                    = "repairs-avonline"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "repairs_alpha_track" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_repairs_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  sheets_credentials_name         = data.aws_ssm_parameter.sheets_credentials_housing_name.value
  google_sheets_document_id       = "1cbeVvMuNNinVQDeVfsUWalRpY6zK9oZPa3ebLtLSiAc"
  google_sheets_worksheet_name    = "Form responses 1"
  department                      = module.department_housing_repairs_data_source
  dataset_name                    = "repairs-alpha-track"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "repairs_stannah" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_repairs_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  sheets_credentials_name         = data.aws_ssm_parameter.sheets_credentials_housing_name.value
  google_sheets_document_id       = "1CpC_Dn4aM8MSFb5a6HJ_FEsVYcahRsis9YIATcfArhw"
  google_sheets_worksheet_name    = "Form responses 1"
  department                      = module.department_housing_repairs_data_source
  dataset_name                    = "repairs-stannah"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "repairs_purdy" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_repairs_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  sheets_credentials_name         = data.aws_ssm_parameter.sheets_credentials_housing_name.value
  google_sheets_document_id       = "1-PpKPnaPMA6AogsNXT5seqQk3VUB-naFnFJYhROkl2o"
  google_sheets_worksheet_name    = "FormresponsesPUR"
  department                      = module.department_housing_repairs_data_source
  dataset_name                    = "repairs-purdy"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "repairs_axis" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_repairs_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  sheets_credentials_name         = data.aws_ssm_parameter.sheets_credentials_housing_name.value
  google_sheets_document_id       = "1aDWO9ZAVar377jiYTXkZzDCIckCqbhppOW23B85hFsA"
  google_sheets_worksheet_name    = "Form responses 1"
  department                      = module.department_housing_repairs_data_source
  dataset_name                    = "repairs-axis"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "parking_spreadsheet_estate_permit_limits" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "14H-kO4wB011ol7J7hLSJ9xv56R4xugmGsZCWNMbe1Ys"
  google_sheets_worksheet_name    = "Import into Qlik Inline Load"
  department                      = module.department_parking_data_source
  dataset_name                    = "estate_permit_limits"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "parking_spreadsheet_parkmap_restrictions_report" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "14Ago8grVd-tW7N0aSlcNZoxzsLDViSYys4shw1wLRno"
  google_sheets_worksheet_name    = "6th June 2019"
  department                      = module.department_parking_data_source
  dataset_name                    = "parkmap_restrictions_report"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "sandbox_daro_covid_locations" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1-ZNoQGu0LGlaKYDBWD8MUo8hqfcnE5YbgCXVz2MUxSw"
  google_sheets_worksheet_name    = "locations"
  department                      = module.department_sandbox_data_source
  dataset_name                    = "daro_covid_locations"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "sandbox_daro_covid_vaccinations" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1-ZNoQGu0LGlaKYDBWD8MUo8hqfcnE5YbgCXVz2MUxSw"
  google_sheets_worksheet_name    = "vaccinations"
  department                      = module.department_sandbox_data_source
  dataset_name                    = "daro_covid_vaccinations"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}
module "covid_locations_lisa" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "187SSANhwBF1SBL8EMG9YMEYcImZDZ4qHdSYlbmwQsjU"
  google_sheets_worksheet_name    = "locations"
  department                      = module.department_sandbox_data_source
  dataset_name                    = "covid-locations-lisa"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}


module "covid_vaccine_demo__locations_tim" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1YNtyajaLORd4bTLP0OIq4B9Z0OtvJHcwOE52ngemqYs"
  google_sheets_worksheet_name    = "locations"
  department                      = module.department_sandbox_data_source
  dataset_name                    = "tim_covid_vaccination_locations"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "covid_vaccine_demo__vaccinatons_tim" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1YNtyajaLORd4bTLP0OIq4B9Z0OtvJHcwOE52ngemqYs"
  google_sheets_worksheet_name    = "vaccinations"
  department                      = module.department_sandbox_data_source
  dataset_name                    = "tim_covid_vaccination_vaccinations"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "covid_vaccinations_lisa" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "187SSANhwBF1SBL8EMG9YMEYcImZDZ4qHdSYlbmwQsjU"
  google_sheets_worksheet_name    = "vaccinations"
  department                      = module.department_sandbox_data_source
  dataset_name                    = "covid-vaccinations-lisa"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "huu_do_covid_vaccinations_locations" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1woiyagiG9ixl5P5d-VN8dubgLyWuT1l1HFv2iqDb6b8"
  google_sheets_worksheet_name    = "locations"
  department                      = module.department_sandbox_data_source
  dataset_name                    = "huu_do_sandbox_covid_locations"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "huu_do_covid_vaccinations_vaccinations" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1woiyagiG9ixl5P5d-VN8dubgLyWuT1l1HFv2iqDb6b8"
  google_sheets_worksheet_name    = "vaccinations"
  department                      = module.department_sandbox_data_source
  dataset_name                    = "huu_do_sandbox_covid_vaccinations"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "sandbox_covid_locations_ben" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1sHtMYXjAmTjkl9rhplvgnCortnqqWa9QMJYJgQr_Mjg"
  google_sheets_worksheet_name    = "locations"
  department                      = module.department_sandbox_data_source
  dataset_name                    = "covid_locations_ben"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "sandbox_covid_vaccinations_ben" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1sHtMYXjAmTjkl9rhplvgnCortnqqWa9QMJYJgQr_Mjg"
  google_sheets_worksheet_name    = "locations"
  department                      = module.department_sandbox_data_source
  dataset_name                    = "covid_vaccinations_ben"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "sandbox_covid_locations_marta" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1r3IzCNqAVmcVgEJ8niLLe5lzT-gvAAAdmIALrPlOpKE"
  google_sheets_worksheet_name    = "locations"
  department                      = module.department_sandbox_data_source
  dataset_name                    = "sandbox_covid_locations_marta"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "sandbox_covid_vaccinations_marta" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1r3IzCNqAVmcVgEJ8niLLe5lzT-gvAAAdmIALrPlOpKE"
  google_sheets_worksheet_name    = "vaccinations"
  department                      = module.department_sandbox_data_source
  dataset_name                    = "sandbox_covid_vaccinations_marta"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "sandbox_covid_vaccinations_adam" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1jUk8NvVOqBNPZHsikoZ8Oi3K9xZbfJza6qOXRS3ewII"
  google_sheets_worksheet_name    = "vaccinations"
  department                      = module.department_sandbox_data_source
  dataset_name                    = "covid_vaccinations_adam"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "sandbox_covid_locations_adam" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1jUk8NvVOqBNPZHsikoZ8Oi3K9xZbfJza6qOXRS3ewII"
  google_sheets_worksheet_name    = "locations"
  department                      = module.department_sandbox_data_source
  dataset_name                    = "covid_locations_adam"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "sandbox_estates_round_crew_data" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1C5Afb_4qz2_7m7xPXAW9g40nWDt1jrdla3TBARAlCEM"
  google_sheets_worksheet_name    = "EstatesRoundCrewData_07032022"
  department                      = module.department_sandbox_data_source
  dataset_name                    = "estate_round_crew_data"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "env_enforcement_asb_warnings" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_env_enforcement_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1lPmgGbN_LuhObVAwE3BPdgUrFEFDWh9he4MO21DrxLY"
  google_sheets_worksheet_name    = "Form responses 1"
  department                      = module.department_env_enforcement_data_source
  dataset_name                    = "asb_warnings"
  enable_glue_trigger             = true
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "sandbox_stevefarr_covid_vaccinations" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1Wlfr6uUcVCMH3hN2GFgNbl0ENB5E14t62imgwk3dfU8"
  google_sheets_worksheet_name    = "vaccinations"
  department                      = module.department_sandbox_data_source
  dataset_name                    = "stevefarr_covid_vaccinations"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "sandbox_stevefarr_covid_locations" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1Wlfr6uUcVCMH3hN2GFgNbl0ENB5E14t62imgwk3dfU8"
  google_sheets_worksheet_name    = "locations"
  department                      = module.department_sandbox_data_source
  dataset_name                    = "stevefarr_covid_locations"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "sandbox_sanch_covid_vaccinations" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1vhChFVYjn78XmCb1ZwodCwWy3YXq7hIyToENsfEgRbc"
  google_sheets_worksheet_name    = "vaccinations"
  department                      = module.department_sandbox_data_source
  dataset_name                    = "sanch_covid_vaccinations"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "sandbox_sanch_covid_locations" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1vhChFVYjn78XmCb1ZwodCwWy3YXq7hIyToENsfEgRbc"
  google_sheets_worksheet_name    = "locations"
  department                      = module.department_sandbox_data_source
  dataset_name                    = "sanch_covid_locations"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "sandbox_jlayton_covid_locations" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1BacwEndkvxOsmst5t9m6kGABkLKTLCzRDUML9TtJAaM"
  google_sheets_worksheet_name    = "locations"
  department                      = module.department_sandbox_data_source
  dataset_name                    = "jlayton_covid_locations"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "sandbox_jlayton_covid_vaccinations" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1BacwEndkvxOsmst5t9m6kGABkLKTLCzRDUML9TtJAaM"
  google_sheets_worksheet_name    = "vaccinations"
  department                      = module.department_sandbox_data_source
  dataset_name                    = "jlayton_covid_vaccinations"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "vaccination_loc_arda" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1-jBGmD0ZQiGiHHZOUxiiz2_PnGw-CEEmN5O4VvMAaco"
  google_sheets_worksheet_name    = "locations"
  department                      = module.department_sandbox_data_source
  dataset_name                    = "arda_covid_vaccination_loc"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "sandbox_everlander_covid_locations" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1FsCa905Xe9aumGtpFdwPVrSbWhEMtasbRT_rKuytAfg"
  google_sheets_worksheet_name    = "locations"
  department                      = module.department_sandbox_data_source
  dataset_name                    = "everlander_covid_locations"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "vaccination_vac_arda" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1-jBGmD0ZQiGiHHZOUxiiz2_PnGw-CEEmN5O4VvMAaco"
  google_sheets_worksheet_name    = "vaccinations"
  department                      = module.department_sandbox_data_source
  dataset_name                    = "arda_covid_vaccination_vac"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "sandbox_everlander_covid_vaccinations" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1FsCa905Xe9aumGtpFdwPVrSbWhEMtasbRT_rKuytAfg"
  google_sheets_worksheet_name    = "vaccinations"
  department                      = module.department_sandbox_data_source
  dataset_name                    = "everlander_covid_vaccinations"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "sandbox_lindseycoulson_covid_vaccinations" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1m8M8lv5-KP6ssbpqzupeLLvsQW6fkNbCOaM2KUcvUTM"
  google_sheets_worksheet_name    = "vaccinations"
  department                      = module.department_sandbox_data_source
  dataset_name                    = "lindseycoulson_covid_vaccinations"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "sandbox_lindseycoulson_covid_locations" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1m8M8lv5-KP6ssbpqzupeLLvsQW6fkNbCOaM2KUcvUTM"
  google_sheets_worksheet_name    = "locations"
  department                      = module.department_sandbox_data_source
  dataset_name                    = "lindseycoulson_covid_locations"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "sandbox_tuomo_covid_vaccinations" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1A4HkdA94G7jXA6zDnHmI2lA6Ttmy4Rj4R0OQPsb4vZ0"
  google_sheets_worksheet_name    = "vaccinations"
  department                      = module.department_sandbox_data_source
  dataset_name                    = "tuomo_covid_vaccinations"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "sandbox_tuomo_covid_locations" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1A4HkdA94G7jXA6zDnHmI2lA6Ttmy4Rj4R0OQPsb4vZ0"
  google_sheets_worksheet_name    = "locations"
  department                      = module.department_sandbox_data_source
  dataset_name                    = "tuomo_covid_locations"
  enable_glue_trigger             = false
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "housing_patches" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1zQ99NFnueXlUm_VcLno2xZQYuDE1Wrll-SZxHALfF-M"
  google_sheets_worksheet_name    = "Property Patch mapping"
  department                      = module.department_housing_data_source
  dataset_name                    = "property_patch_mapping"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "officer_patches" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1zQ99NFnueXlUm_VcLno2xZQYuDE1Wrll-SZxHALfF-M"
  google_sheets_worksheet_name    = "Officer - Patch mapping"
  department                      = module.department_housing_data_source
  dataset_name                    = "officer_patch_mapping"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}


module "parking_spreadsheet_parking_ops_db_defects_mgt" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "158a8akavRN3nuYm04tyUac-zVZAOjLiPU4O8tCrPYpw"
  google_sheets_worksheet_name    = "dp_data_import"
  department                      = module.department_parking_data_source
  dataset_name                    = "parking_ops_db_defects_mgt"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}
    
module "housing_rent_patches" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1LeIsJJIlcPB0yXMlP-L7KPDjvzyaFqhXyahKCiysEu4"
  google_sheets_worksheet_name    = "List of properties"
  department                      = module.department_housing_data_source
  dataset_name                    = "property_rent_patches"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "rent_officer_patches" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1LeIsJJIlcPB0yXMlP-L7KPDjvzyaFqhXyahKCiysEu4"
  google_sheets_worksheet_name    = "Patch List"
  department                      = module.department_housing_data_source
  dataset_name                    = "rent_officer_patch_mapping"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

    
module "parking_spreadsheet_eta_decisions_gds_qlik_data_load" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1M-kXwuwnYAnd2VEAcnmBR5SRPK49ooJBwXXbVIUkr3I"
  google_sheets_worksheet_name    = "dp_data_import"
  department                      = module.department_parking_data_source
  dataset_name                    = "parking_eta_decisions_gds_qlik_data_load"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}
    
module "dp_success_measures_auto_data" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  glue_catalog_database_name      = module.department_data_and_insight_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1T3EyKOoFbaWSx6Gsp-mOJc9DSB-EsaKitqitLxCAY50"
  google_sheets_worksheet_name    = "Automated Data"
  department                      = module.department_data_and_insight_data_source
  dataset_name                    = "dp_success_measures_automated_data"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}
