module "address_matching_glue_job" {
  source = "../modules/aws-glue-job"

  count = local.is_live_environment ? 1 : 0

  department             = module.department_housing_repairs
  job_name               = "${local.short_identifier_prefix}Address Matching"
  glue_scripts_bucket_id = module.glue_scripts.bucket_id
  job_parameters = {
    "--perfect_match_s3_bucket_target" = "s3://${module.landing_zone.bucket_id}/data-and-insight/address-matching-glue-job-output/perfect_match_s3_bucket_target"
    "--best_match_s3_bucket_target"    = "s3://${module.landing_zone.bucket_id}/data-and-insight/address-matching-glue-job-output/best_match_s3_bucket_target"
    "--non_match_s3_bucket_target"     = "s3://${module.landing_zone.bucket_id}/data-and-insight/address-matching-glue-job-output/non_match_s3_bucket_target"
    "--imperfect_s3_bucket_target"     = "s3://${module.landing_zone.bucket_id}/data-and-insight/address-matching-glue-job-output/imperfect_s3_bucket_target"
    "--query_addresses_url"            = "s3://${module.landing_zone.bucket_id}/data-and-insight/address-matching-test/test_addresses.gz.parquet"
    "--target_addresses_url"           = "s3://${module.landing_zone.bucket_id}/data-and-insight/address-matching-test/addresses_api_full.gz.parquet"
    "--extra-py-files"                 = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
  script_name = aws_s3_bucket_object.address_matching.key
  crawler_details = {
    database_name      = aws_glue_catalog_database.landing_zone_data_and_insight_address_matching[count.index].name
    s3_target_location = "s3://${module.landing_zone.bucket_id}/data-and-insight/address-matching-glue-job-output/"
  }
}

module "address_cleaning_glue_job" {
  source = "../modules/aws-glue-job"

  count = local.is_live_environment ? 1 : 0

  department             = module.department_housing_repairs
  job_name               = "${local.short_identifier_prefix}Housing Repairs - Address Cleaning"
  glue_scripts_bucket_id = module.glue_scripts.bucket_id
  job_parameters = {
    "--TempDir"        = module.glue_temp_storage.bucket_url
    "--extra-py-files" = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key},s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.repairs_cleaning_helpers.key}"
  }
  script_name = aws_s3_bucket_object.address_cleaning.key
}

module "manually_uploaded_parking_data_to_raw" {
  source = "../modules/aws-glue-job"

  count = local.is_live_environment ? 1 : 0

  department             = module.department_parking
  job_name               = "${local.short_identifier_prefix}Parking Copy Manually Uploaded CSVs to Raw"
  glue_scripts_bucket_id = module.glue_scripts.bucket_id
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-enable"
    "--s3_bucket_target"    = module.raw_zone.bucket_id
    "--s3_bucket_source"    = module.landing_zone.bucket_id
    "--s3_prefix"           = "parking/manual/"
    "--extra-py-files"      = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
  script_name     = aws_s3_bucket_object.copy_manually_uploaded_csv_data_to_raw.key
  trigger_enabled = false
  crawler_details = {
    database_name      = module.department_parking.raw_zone_catalog_database_name
    s3_target_location = "s3://${module.raw_zone.bucket_id}/parking/manual/"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableLevelConfiguration = 4
      }
    })
  }
}
