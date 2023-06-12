module "address_matching_glue_job" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  count = local.is_live_environment ? 1 : 0

  department                 = module.department_housing_repairs_data_source
  job_name                   = "${local.short_identifier_prefix}Address Matching"
  helper_module_key          = data.aws_s3_object.helpers.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  pydeequ_zip_key            = data.aws_s3_object.pydeequ.key
  job_parameters = {
    "--perfect_match_s3_bucket_target" = "s3://${module.landing_zone_data_source.bucket_id}/data-and-insight/address-matching-glue-job-output/perfect_match_s3_bucket_target"
    "--best_match_s3_bucket_target"    = "s3://${module.landing_zone_data_source.bucket_id}/data-and-insight/address-matching-glue-job-output/best_match_s3_bucket_target"
    "--non_match_s3_bucket_target"     = "s3://${module.landing_zone_data_source.bucket_id}/data-and-insight/address-matching-glue-job-output/non_match_s3_bucket_target"
    "--imperfect_s3_bucket_target"     = "s3://${module.landing_zone_data_source.bucket_id}/data-and-insight/address-matching-glue-job-output/imperfect_s3_bucket_target"
    "--query_addresses_url"            = "s3://${module.landing_zone_data_source.bucket_id}/data-and-insight/address-matching-test/test_addresses.gz.parquet"
    "--target_addresses_url"           = "s3://${module.landing_zone_data_source.bucket_id}/data-and-insight/address-matching-test/addresses_api_full.gz.parquet"
  }
  script_s3_object_key = aws_s3_object.address_matching.key
  crawler_details = {
    database_name      = aws_glue_catalog_database.landing_zone_data_and_insight_address_matching[count.index].name
    s3_target_location = "s3://${module.landing_zone_data_source.bucket_id}/data-and-insight/address-matching-glue-job-output/"
    configuration      = null
    table_prefix       = null 
  }
}

module "address_cleaning_glue_job" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  count = local.is_live_environment ? 1 : 0

  department                 = module.department_housing_repairs_data_source
  job_name                   = "${local.short_identifier_prefix}Housing Repairs - Address Cleaning"
  helper_module_key          = data.aws_s3_object.helpers.key
  pydeequ_zip_key            = data.aws_s3_object.pydeequ.key
  script_s3_object_key       = aws_s3_object.address_cleaning.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
}
