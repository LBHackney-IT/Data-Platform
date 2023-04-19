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
  create_workflow                 = true
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
  create_workflow                 = true
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
  create_workflow                 = true
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
  create_workflow                 = true
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
  create_workflow                 = true
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
  create_workflow                 = true
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
  create_workflow                 = true
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
  google_sheets_worksheet_name    = "records"
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


module "correspondence_performance_officer_qa_name_link_lookup" {
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
  google_sheets_document_id       = "1DxIXHxNSXNrIHTk7-vHiWLnM0S_mDczBhWqbJ3e7BAE"
  google_sheets_worksheet_name    = "officer_lookup"
  department                      = module.department_parking_data_source
  dataset_name                    = "correspondence_performance_officer_qa_name_link_lookup"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "dp_success_measures_metrics" {
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
  google_sheets_worksheet_name    = "Metrics"
  department                      = module.department_data_and_insight_data_source
  dataset_name                    = "dp_success_measures_metrics"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "parking_spreadsheet_parking_ops_cycle_hangar_mgt" {
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
  google_sheets_document_id       = "1g3gdRg_TgCA4ra9m_UrevaK7GYUXIOb5FKPVNF4uz44"
  google_sheets_worksheet_name    = "Repair details"
  department                      = module.department_parking_data_source
  dataset_name                    = "parking_ops_cycle_hangar_mgt"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "qa_correspondence_teams_data_load" {
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
  google_sheets_document_id       = "1zxZXX1_qU9NW93Ug1JUy7aXsnTz45qIj7Zftmi9trbI"
  google_sheets_worksheet_name    = "team_officer_list"
  department                      = module.department_parking_data_source
  dataset_name                    = "correspondence_performance_teams"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "qa_correspondence_targets_desc_data_load" {
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
  google_sheets_document_id       = "14BHmGH3_Lr97vHqkPbOvFM0chHpEqcYXLGrtXDW1jGE"
  google_sheets_worksheet_name    = "target_name_description"
  department                      = module.department_parking_data_source
  dataset_name                    = "qa_correspondence_targets_desc"
  google_sheet_import_schedule    = "cron(0 3 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "qa_correspondence_targets_data_load" {
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
  google_sheets_document_id       = "14BHmGH3_Lr97vHqkPbOvFM0chHpEqcYXLGrtXDW1jGE"
  google_sheets_worksheet_name    = "target"
  department                      = module.department_parking_data_source
  dataset_name                    = "qa_correspondence_targets"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "quality_performance_knowledge_hub_data_load" {
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
  google_sheets_document_id       = "19W3S4QDHL9k15zrxEXT9AFRv3hQ0O9roOAL7lZ1hw3c"
  google_sheets_worksheet_name    = "quality_performance_knowledge_hub_data_load"
  department                      = module.department_parking_data_source
  dataset_name                    = "quality_performance_knowledge_hub"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "parking_officer_downtime_data_load" {
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
  google_sheets_document_id       = "1DTSH8p1b9IVVoJMK1ywq4M6WzpVTZHR4LVyTeOhGOwk"
  google_sheets_worksheet_name    = "parking_officer_downtime_data_load"
  department                      = module.department_parking_data_source
  dataset_name                    = "officer_downtime"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "qa_correspondence_individual_target_data_load" {
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
  google_sheets_document_id       = "1wO5D0xh5peNvrg4MrBNh5WGIIutDwNKA0zQB9zxBxTA"
  google_sheets_worksheet_name    = "qa_correspondence_individual_target_data_load"
  department                      = module.department_parking_data_source
  dataset_name                    = "qa_correspondence_individual_target"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}
