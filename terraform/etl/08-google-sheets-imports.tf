module "repairs_dlo" {
  count = local.is_live_environment ? 1 : 0

  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_repairs_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
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
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_repairs_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
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
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_repairs_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
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
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_repairs_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
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
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_repairs_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
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
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_repairs_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
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
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_repairs_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
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
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
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
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
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
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_sandbox_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
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
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
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
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
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
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
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
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
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
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
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
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1M-kXwuwnYAnd2VEAcnmBR5SRPK49ooJBwXXbVIUkr3I"
  google_sheets_worksheet_name    = "records"
  department                      = module.department_parking_data_source
  dataset_name                    = "parking_eta_decisions_gds_qlik_data_load"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
  enable_glue_trigger             = false
}

module "dp_success_measures_auto_data" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_data_and_insight_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
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
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
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
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_data_and_insight_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
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
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
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
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
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
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
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
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
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
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
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
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
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
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1wO5D0xh5peNvrg4MrBNh5WGIIutDwNKA0zQB9zxBxTA"
  google_sheets_worksheet_name    = "qa_correspondence_individual_target_data_load"
  department                      = module.department_parking_data_source
  dataset_name                    = "qa_correspondence_individual_target"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "eta_log_data_load" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1c0UhiqmKT5O7dObfxKRzxUAJdZ0eexpn92_xVt8lPpg"
  google_sheets_worksheet_name    = "eta_log_data_load"
  department                      = module.department_parking_data_source
  dataset_name                    = "eta_log"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "wsbox2_log_data_load" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1b0MnZDtk_ooV6BSwK1HuRSDiSbF06ReskyMGjHhsQuA"
  google_sheets_worksheet_name    = "wsbox2_log_data_load"
  department                      = module.department_parking_data_source
  dataset_name                    = "wsbox2_log"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "wsbox3_log_data_load" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1jh-9xOXpitQACaqa_p2sA0Sl1Qujples2jFYYA6rq70"
  google_sheets_worksheet_name    = "wsbox3_log_data_load"
  department                      = module.department_parking_data_source
  dataset_name                    = "wsbox3_log"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "parking_spreadsheet_eta_decision_gds_qlik_data_load" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1M-kXwuwnYAnd2VEAcnmBR5SRPK49ooJBwXXbVIUkr3I"
  google_sheets_worksheet_name    = "records"
  department                      = module.department_parking_data_source
  dataset_name                    = "eta_decision_records"
  google_sheet_import_schedule    = "cron(0 5 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "parking_spreadsheet_parking_ops_cycle_hangar_list" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1joEMPhf2TZ3i4gvnhUd0loonQd65Pfg4z51z9eP-z0w"
  google_sheets_worksheet_name    = "Hangar list"
  department                      = module.department_parking_data_source
  dataset_name                    = "parking_ops_cycle_hangar_list"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}
module "parking_spreadsheet_parking_ops_suspension_data" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1GuT2vu5p3KIKc85gsj5w99oeODgnlJs2w8l79RM9-fc"
  google_sheets_worksheet_name    = "jobs"
  department                      = module.department_parking_data_source
  dataset_name                    = "parking_ops_suspension_data"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}
module "parking_gm_cycle_hangar_installation_data" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1yNN1u3NHZT08P7uGsIkrYSghKvs5Gk8maKx3H2UJaAc"
  google_sheets_worksheet_name    = "installations record"
  department                      = module.department_parking_data_source
  dataset_name                    = "parking_ops_gm_cycle_hangar_installation_data"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "nas_live_manual_updates_data_load" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1Xf8nBhIW6wyvNOU7JOWSCJwZvsx65T9ZWYSct9vj9Gw"
  google_sheets_worksheet_name    = "nas_live_manual_updates_data_load"
  department                      = module.department_parking_data_source
  dataset_name                    = "nas_live_manual_updates_data_load"
  google_sheet_import_schedule    = "cron(0 4 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "homeowner_record_sheet" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1xqqk18GySlEHdbgl01VScViG03qIRCUiJVEsLHKClio"
  google_sheets_worksheet_name    = "Homeowner record sheet"
  department                      = module.department_housing_data_source
  dataset_name                    = "homeowner_record_sheet"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "dwellings_list" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1QgKCWrJlY5iLUrCKSJdhTaDlkASiuqFnkLwTe9lyIyE"
  google_sheets_worksheet_name    = "Dwellings List"
  department                      = module.department_housing_data_source
  dataset_name                    = "dwellings_list"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "lift_names" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "10R-Rux76cFTF286czS111U49qR75xdJKHxnwpXIdIzc"
  google_sheets_worksheet_name    = "Lift Names"
  department                      = module.department_housing_data_source
  dataset_name                    = "lift_names"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "hra_stock_count" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1G_nbzd4ek-KC2bjcxZQ8-E3jFUO1rJ7aYGERQ15qQ80"
  google_sheets_worksheet_name    = "HRA Stock Count 2024-25 wip"
  google_sheet_header_row_number  = 3
  department                      = module.department_housing_data_source
  dataset_name                    = "hra_stock_count_2024_25"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
  enable_glue_trigger             = false
}

module "hostels_stock_count" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_housing_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1G_nbzd4ek-KC2bjcxZQ8-E3jFUO1rJ7aYGERQ15qQ80"
  google_sheets_worksheet_name    = "Hostels Stock Count 2024-25 wip"
  google_sheet_header_row_number  = 2
  department                      = module.department_housing_data_source
  dataset_name                    = "hostels_stock_count_2024_25"
  google_sheet_import_schedule    = "cron(0 6 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
  enable_glue_trigger             = false
}

module "permits_consultation_survey_data_load" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1LNQbeHlsMm7B74ZXT1FwMwl06FS7MS7QjgzrktWr5TQ"
  google_sheets_worksheet_name    = "Import_source_sheet"
  department                      = module.department_parking_data_source
  dataset_name                    = "permits_consultation_survey_data_load"
  google_sheet_import_schedule    = "cron(0 13 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "abandoned_vehicles_investigation_log_data_load" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1hQpFGnDW1bbs66sLiQuNe6N_KLTG78_wMBYrHKMJ5_U"
  google_sheets_worksheet_name    = "data_import_sheet"
  department                      = module.department_parking_data_source
  dataset_name                    = "abandoned_vehicles_investigation_log_data_load"
  google_sheet_import_schedule    = "cron(0 4 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}
module "parking_cycle_hangar_manual_waiting_list" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1dP502pWXCzBz3QJjlhPVJnrKVXHrdu8jP3hEfa5sxeI"
  google_sheets_worksheet_name    = "Sheet1"
  department                      = module.department_parking_data_source
  dataset_name                    = "parking_cycle_hangar_manual_waiting_list"
  google_sheet_import_schedule    = "cron(0 4 ? * * *)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}

module "diplomatic_country_vrm_prefix_data_load" {
  count                           = local.is_live_environment ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  is_production_environment       = local.is_production_environment
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_scripts_bucket_id          = module.glue_scripts_data_source.bucket_id
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_catalog_database_name      = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_url    = module.glue_temp_storage_data_source.bucket_url
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone_data_source.bucket_id
  google_sheets_document_id       = "1ui4i40sEp_wVlxVjcOhcQnhp2ucPpAQ9hALGJ7K76i0"
  google_sheets_worksheet_name    = "diplomatic_country_vrm_prefix_data_load"
  department                      = module.department_parking_data_source
  dataset_name                    = "diplomatic_country_vrm_prefix_data_load"
  google_sheet_import_schedule    = "cron(0 4 * * 1)"
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
}
