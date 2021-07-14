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
    "--TempDir"                            = module.glue_temp_storage.bucket_url
    "--extra-py-files"                     = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
}

resource "aws_glue_job" "manually_uploaded_parking_data_to_raw" {
  count = local.is_live_environment ? 1 : 0

  tags = module.tags.values

  name              = "${local.short_identifier_prefix}Parking Import Manually Uploaded CSVs to Raw"
  number_of_workers = 2
  worker_type       = "Standard"
  role_arn          = aws_iam_role.glue_role.arn
  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.import_manually_uploaded_csv_data_to_raw.key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--job-bookmark-option" = "job-bookmark-enable"
    "--s3_bucket_target"    = module.raw_zone.bucket_id
    "--s3_bucket_source"    = module.landing_zone.bucket_id
    "--s3_prefix"           = "parking/manual/"
    "--extra-py-files"      = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
}

resource "aws_glue_job" "copy_parking_liberator_landing_to_raw" {
  tags = module.tags.values

  name              = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  number_of_workers = 2
  worker_type       = "Standard"
  role_arn          = aws_iam_role.glue_role.arn
  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.copy_parking_liberator_landing_to_raw.key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--job-bookmark-option"       = "job-bookmark-enable"
    "--s3_bucket_target"          = module.raw_zone.bucket_id
    "--s3_prefix"                 = "parking/liberator/"
    "--table_filter_expression"   = "^liberator_(?!fpn).*"
    "--glue_database_name_source" = aws_glue_catalog_database.landing_zone_liberator.name
    "--glue_database_name_target" = aws_glue_catalog_database.raw_zone_liberator.name
    "--extra-py-files"            = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
}

resource "aws_glue_job" "repairs_dlo_levenshtein_address_matching" {
  count = local.is_live_environment ? 1 : 0

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
    "--TempDir"                     = module.glue_temp_storage.bucket_url
    "--extra-py-files"              = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
}

resource "aws_glue_job" "get_uprn_from_uhref" {
  count = local.is_live_environment ? 1 : 0

  tags = module.tags.values

  name              = "${local.short_identifier_prefix}Get UPRN from UHref"
  number_of_workers = 10
  worker_type       = "G.1X"
  role_arn          = aws_iam_role.glue_role.arn
  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.get_uprn_from_uhref.key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--lookup_catalogue_table"      = "datainsight_data_and_insight"
    "--lookup_database"             = "dataplatform-stg-raw-zone-database"
    "--source_data_catalogue_table" = "housing_repairs_repairs_dlo_with_cleaned_addresses_with_cleaned_addresses"
    "--source_data_database"        = module.department_housing_repairs.refined_zone_catalog_database_name
    "--target_destination"          = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/with_uprn_from_uhref/"
    "--TempDir"                     = "s3://${module.glue_temp_storage.bucket_arn}/"
    "--extra-py-files"              = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
}

resource "aws_glue_workflow" "parking_liberator_data" {
  # This resource is modified outside of terraform by parking analysts.
  # Any change which forces the workflow to be recreated will lose their changes.
  name = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  tags = module.tags.values
}
