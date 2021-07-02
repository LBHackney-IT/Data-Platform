module "repairs_DLO" {
  count                           = terraform.workspace == "default" ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  helpers_script_key              = aws_s3_bucket_object.helpers.key
  glue_catalog_database_name      = module.department_housing_repairs.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id     = module.glue_temp_storage.bucket_arn
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  tags                            = module.tags.values
  glue_job_name                   = "DLO Repairs"
  google_sheets_document_id       = "1i9q42Kkbugwi4f2S4zdyid2ZjoN1XLjuYvqYqfHyygs"
  google_sheets_worksheet_name    = "Form responses 1"
  department_name                 = "housing-repairs"
  dataset_name                    = "repairs-dlo"
}

module "repairs_herts_heritage" {
  count                           = terraform.workspace == "default" ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  helpers_script_key              = aws_s3_bucket_object.helpers.key
  glue_catalog_database_name      = module.department_housing_repairs.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id     = module.glue_temp_storage.bucket_arn
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  tags                            = module.tags.values
  glue_job_name                   = "Herts Heritage Repairs"
  google_sheets_document_id       = "1Psw8i2qooASPLjaBfGKNX7upiX7BeQSiMeJ8dQngSJI"
  google_sheets_worksheet_name    = "Form responses 1"
  department_name                 = "housing-repairs"
  dataset_name                    = "repairs-herts-heritage"
}

module "repairs_avonline" {
  count                           = terraform.workspace == "default" ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  helpers_script_key              = aws_s3_bucket_object.helpers.key
  glue_catalog_database_name      = module.department_housing_repairs.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id     = module.glue_temp_storage.bucket_arn
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  tags                            = module.tags.values
  glue_job_name                   = "Avonline Repairs"
  google_sheets_document_id       = "1nM99bPaOPvg5o_cz9_yJR6jlnMB0oSHdFhAMKQkPJi4"
  google_sheets_worksheet_name    = "Form responses 1"
  department_name                 = "housing-repairs"
  dataset_name                    = "repairs-avonline"
}

module "repairs_alpha_track" {
  count                           = terraform.workspace == "default" ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  helpers_script_key              = aws_s3_bucket_object.helpers.key
  glue_catalog_database_name      = module.department_housing_repairs.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id     = module.glue_temp_storage.bucket_arn
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  tags                            = module.tags.values
  glue_job_name                   = "Alpha Track Repairs"
  google_sheets_document_id       = "1cbeVvMuNNinVQDeVfsUWalRpY6zK9oZPa3ebLtLSiAc"
  google_sheets_worksheet_name    = "Form responses 1"
  department_name                 = "housing-repairs"
  dataset_name                    = "repairs-alpha-track"
}

module "repairs_stannah" {
  count                           = terraform.workspace == "default" ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  helpers_script_key              = aws_s3_bucket_object.helpers.key
  glue_catalog_database_name      = module.department_housing_repairs.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id     = module.glue_temp_storage.bucket_arn
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  tags                            = module.tags.values
  glue_job_name                   = "Stannah Repairs"
  google_sheets_document_id       = "1CpC_Dn4aM8MSFb5a6HJ_FEsVYcahRsis9YIATcfArhw"
  google_sheets_worksheet_name    = "Form responses 1"
  department_name                 = "housing-repairs"
  dataset_name                    = "repairs-stannah"
}

module "repairs_purdy" {
  count                           = terraform.workspace == "default" ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  helpers_script_key              = aws_s3_bucket_object.helpers.key
  glue_catalog_database_name      = module.department_housing_repairs.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id     = module.glue_temp_storage.bucket_arn
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  tags                            = module.tags.values
  glue_job_name                   = "Purdy Repairs"
  google_sheets_document_id       = "1-PpKPnaPMA6AogsNXT5seqQk3VUB-naFnFJYhROkl2o"
  google_sheets_worksheet_name    = "FormresponsesPUR"
  department_name                 = "housing-repairs"
  dataset_name                    = "repairs-purdy"
}

module "repairs_axis" {
  count                           = terraform.workspace == "default" ? 1 : 0
  source                          = "../modules/google-sheets-glue-job"
  identifier_prefix               = local.short_identifier_prefix
  is_live_environment             = local.is_live_environment
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  helpers_script_key              = aws_s3_bucket_object.helpers.key
  glue_catalog_database_name      = module.department_housing_repairs.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id     = module.glue_temp_storage.bucket_arn
  glue_crawler_excluded_blobs     = local.glue_crawler_excluded_blobs
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  bucket_id                       = module.raw_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  tags                            = module.tags.values
  glue_job_name                   = "Axis Repairs"
  google_sheets_document_id       = "1aDWO9ZAVar377jiYTXkZzDCIckCqbhppOW23B85hFsA"
  google_sheets_worksheet_name    = "Form responses 1"
  department_name                 = "housing-repairs"
  dataset_name                    = "repairs-axis"
}

module "import-repairs-fire-alarms-xlsx-file-format" {
  count = terraform.workspace == "default" ? 1 : 0

  source                      = "../modules/xlsx-import-job"
  glue_role_arn               = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id      = module.glue_scripts.bucket_id
  glue_temp_storage_bucket_id = module.glue_temp_storage.bucket_arn
  helpers_script_key          = aws_s3_bucket_object.helpers.key
  xlsx_import_script_key      = aws_s3_bucket_object.xlsx_import_script.key
  landing_zone_bucket_id      = module.landing_zone.bucket_id
  tags                        = module.tags.values
  glue_job_name               = "Fire Alarm AOV"
  department_folder_name      = "housing"
  output_folder_name          = "Fire_Alarm_AOV"
  raw_zone_bucket_id          = module.raw_zone.bucket_id
  input_file_name             = "electrical_mechnical_fire_safety_temp_order_number_wc_12.10.20r1.xlsx"
  header_row_number           = 1
  worksheet_name              = "Fire AlarmAOV"
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
    "--perfect_match_s3_bucket_target" = "s3://${module.landing_zone.bucket_id}/data-and-insight/address-matching-glue-job-output/perfect_match_s3_bucket_target"
    "--best_match_s3_bucket_target"    = "s3://${module.landing_zone.bucket_id}/data-and-insight/address-matching-glue-job-output/best_match_s3_bucket_target"
    "--non_match_s3_bucket_target"     = "s3://${module.landing_zone.bucket_id}/data-and-insight/address-matching-glue-job-output/non_match_s3_bucket_target"
    "--imperfect_s3_bucket_target"     = "s3://${module.landing_zone.bucket_id}/data-and-insight/address-matching-glue-job-output/imperfect_s3_bucket_target"
    "--query_addresses_url"            = "s3://${module.landing_zone.bucket_id}/data-and-insight/address-matching-test/test_addresses.gz.parquet"
    "--target_addresses_url"           = "s3://${module.landing_zone.bucket_id}/data-and-insight/address-matching-test/addresses_api_full.gz.parquet"
    "--extra-py-files"                 = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
}
resource "aws_glue_job" "repairs_dlo_cleaning_glue_job" {
  count = terraform.workspace == "default" ? 1 : 0

  tags = module.tags.values

  name              = "Repairs-dlo cleaning"
  number_of_workers = 10
  worker_type       = "G.1X"
  role_arn          = aws_iam_role.glue_role.arn
  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.repairs_dlo_cleaning_script.key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--source_catalog_database"          = module.department_housing_repairs.raw_zone_catalog_database_name
    "--source_catalog_table"             = "housing_repairs_repairs_dlo"
    "--cleaned_repairs_s3_bucket_target" = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/cleaned"
    "--TempDir"                          = "s3://${module.glue_temp_storage.bucket_arn}/"
    "--extra-py-files"                   = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
}


resource "aws_glue_job" "address_cleaning_glue_job" {
  count = terraform.workspace == "default" ? 1 : 0

  tags = module.tags.values

  name              = "Address Cleaning"
  number_of_workers = 10
  worker_type       = "G.1X"
  role_arn          = aws_iam_role.glue_role.arn
  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.address_cleaning.key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--cleaned_addresses_s3_bucket_target" = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/with-cleaned-addresses"
    "--source_catalog_database"            = module.department_housing_repairs.refined_zone_catalog_database_name
    "--source_catalog_table"               = "housing_repairs_repairs_dlo_cleaned"
    "--source_address_column_header"       = "property_address"
    "--source_postcode_column_header"      = "postal_code_raw"
    "--TempDir"                            = "s3://${module.glue_temp_storage.bucket_arn}/"
    "--extra-py-files"                   = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
}



resource "aws_glue_job" "housing_repairs_alpha_track_cleaning" {
  count = terraform.workspace == "default" ? 1 : 0

  tags = module.tags.values

  name              = "Housing Repairs Alpha-track Cleaning"
  number_of_workers = 10
  worker_type       = "G.1X"
  role_arn          = aws_iam_role.glue_role.arn
  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.repairs_alphatrack_cleaning_script.key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--cleaned_repairs_s3_bucket_target" = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-alpha-track/cleaned"
    "--source_catalog_database"            = module.department_housing_repairs.raw_zone_catalog_database_name
    "--source_catalog_table"               = "housing_repairs_repairs_alpha_track"
    "--TempDir"                            = "s3://${module.glue_temp_storage.bucket_arn}/"
    "--extra-py-files"                   = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
}


resource "aws_glue_job" "manually_uploaded_parking_data_to_raw" {
  tags = module.tags.values

  name              = "${local.environment} Parking copy manually uploaded CSVs to raw"
  number_of_workers = 2
  worker_type       = "Standard"
  role_arn          = aws_iam_role.glue_role.arn
  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.copy_manually_uploaded_csv_data_to_raw.key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--job-bookmark-option" = "job-bookmark-enable"
    "--s3_bucket_target"    = module.raw_zone.bucket_id
    "--s3_bucket_source"    = module.landing_zone.bucket_id
    "--s3_prefix"           = "parking/manual/"
    "--extra-py-files"      = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.get_s3_subfolders.key}, s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
}

resource "aws_glue_job" "repairs_dlo_levenshtein_address_matching" {
  count = terraform.workspace == "default" ? 1 : 0

  tags = module.tags.values

  name              = "Housing Repairs - Repairs DLO Levenshtein Address Matching"
  number_of_workers = 10
  worker_type       = "G.1X"
  role_arn          = aws_iam_role.glue_role.arn
  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.levenshtein_address_matching.key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--addresses_api_data_database"    = aws_glue_catalog_database.raw_zone_unrestricted_address_api.name
    "--addresses_api_data_table"       = "unrestricted_address_api_dbo.hackney_address"
    "--source_catalog_database"        = "housing-repairs-refined-zone"
    "--source_catalog_table"           = "housing_repairs_repairs_dlo_with_cleaned_addresses_with_cleaned_addresses"
    "--target_destination"             = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/with-matched-addresses/"
    "--TempDir"                        = "s3://${module.glue_temp_storage.bucket_arn}/"
    "--extra-py-files"                 = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
}

resource "aws_glue_workflow" "liberator_data" {
  name = "${local.identifier_prefix}-liberator-data-workflow"
}
