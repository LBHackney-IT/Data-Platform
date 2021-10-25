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

resource "aws_glue_job" "address_cleaning" {
  count = local.is_live_environment ? 1 : 0

  tags = module.tags.values

  name              = "${local.short_identifier_prefix}Housing Repairs - Address Cleaning"
  number_of_workers = 10
  worker_type       = "G.1X"
  role_arn          = aws_iam_role.glue_role.arn
  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.address_cleaning.key}"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  glue_version = "2.0"

  default_arguments = {
    "--TempDir"        = module.glue_temp_storage.bucket_url
    "--extra-py-files" = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key},s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.repairs_cleaning_helpers.key}"
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
    "--extra-py-files"      = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
}