module "repairs_fire_alarm_aov" {
  count = local.is_live_environment ? 1 : 0

  source                         = "../modules/import-xlsx-file-from-g-drive"
  glue_role_arn                  = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
  glue_catalog_database_name     = module.department_housing_repairs.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage.bucket_arn
  helpers_script_key             = aws_s3_bucket_object.helpers.key
  xlsx_import_script_key         = aws_s3_bucket_object.xlsx_import_script.key
  identifier_prefix              = local.identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
  landing_zone_bucket_id         = module.landing_zone.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone.bucket_arn
  tags                           = module.tags.values
  google_sheets_document_id      = "1VlM80P6J8N0P3ZeU8VobBP9kMbpr1Lzq"
  glue_job_name                  = "repairs spreadsheet"
  department_folder_name         = "housing"
  output_folder_name             = "repairs_spreadsheet"
  raw_zone_bucket_id             = module.raw_zone.bucket_id
  input_file_name                = "electrical_mechnical_fire_safety_temp_order_number_wc_12.10.20r1.xlsx"
  worksheets = {
    sheet1 : {
      header_row_number = 1
      worksheet_name    = "Fire AlarmAOV"
    }
    sheet2 : {
      header_row_number = 1
      worksheet_name    = "Door Entry"
    }
  }
}

resource "aws_glue_job" "address_matching_glue_job" {
  count = local.is_live_environment ? 1 : 0

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
resource "aws_glue_job" "repairs_dlo_cleaning" {
  count = local.is_live_environment ? 1 : 0

  tags = module.tags.values

  name              = "${local.short_identifier_prefix}Housing Repairs - Repairs DLO Cleaning"
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

resource "aws_glue_job" "repairs_dlo_address_cleaning" {
  count = local.is_live_environment ? 1 : 0

  tags = module.tags.values

  name              = "${local.short_identifier_prefix}Housing Repairs - Repairs DLO Address Cleaning"
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
    "--extra-py-files"                     = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
}

resource "aws_glue_job" "housing_repairs_alpha_track_cleaning" {
  count = local.is_live_environment ? 1 : 0

  tags = module.tags.values

  name              = "${local.short_identifier_prefix}Housing Repairs - Alpha Track Cleaning"
  number_of_workers = 10
  worker_type       = "G.1X"
  role_arn          = aws_iam_role.glue_role.arn
  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.repairs_alpha_track_cleaning_script.key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--cleaned_repairs_s3_bucket_target" = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-alpha-track/cleaned"
    "--source_catalog_database"          = module.department_housing_repairs.raw_zone_catalog_database_name
    "--source_catalog_table"             = "housing_repairs_repairs_alpha_track"
    "--TempDir"                          = "s3://${module.glue_temp_storage.bucket_arn}/"
    "--extra-py-files"                   = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
}


resource "aws_glue_job" "housing_repairs_avonline_cleaning" {
  count = terraform.workspace == "default" ? 1 : 0

  tags = module.tags.values

  name              = "Housing Repairs Avonline Cleaning"
  number_of_workers = 10
  worker_type       = "G.1X"
  role_arn          = aws_iam_role.glue_role.arn
  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.repairs_avonline_cleaning_script.key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--cleaned_repairs_s3_bucket_target" = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-avonline/cleaned"
    "--source_catalog_database"            = module.department_housing_repairs.raw_zone_catalog_database_name
    "--source_catalog_table"               = "housing_repairs_repairs_avonline"
    "--TempDir"                            = "s3://${module.glue_temp_storage.bucket_arn}/"
    "--extra-py-files"                   = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
}


resource "aws_glue_job" "manually_uploaded_parking_data_to_raw" {
  count = local.is_live_environment ? 1 : 0

  tags = module.tags.values

  name              = "${local.short_identifier_prefix}Parking Copy Manually Uploaded CSVs to Raw"
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
    "--addresses_api_data_database" = aws_glue_catalog_database.raw_zone_unrestricted_address_api.name
    "--addresses_api_data_table"    = "unrestricted_address_api_dbo_hackney_address"
    "--source_catalog_database"     = "housing-repairs-refined-zone"
    "--source_catalog_table"        = "housing_repairs_repairs_dlo_with_cleaned_addresses_with_cleaned_addresses"
    "--target_destination"          = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/with-matched-addresses/"
    "--TempDir"                     = "s3://${module.glue_temp_storage.bucket_arn}/"
    "--extra-py-files"              = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
}

resource "aws_glue_workflow" "parking_liberator_data" {
  # This resource is modified outside of terraform by parking analysts.
  # Any change which forces the workflow to be recreated will lose their changes.
  name = "${local.short_identifier_prefix}parking-liberator-data-workflow"
}
