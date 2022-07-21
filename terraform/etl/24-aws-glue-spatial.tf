module "llpg_raw_to_trusted" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department                 = module.department_unrestricted_data_source
  job_name                   = "${local.short_identifier_prefix}llpg_latest_to_trusted"
  glue_job_worker_type       = "G.1X"
  helper_module_key          = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key            = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  job_parameters = {
    "--job-bookmark-option"     = "job-bookmark-enable"
    "--s3_bucket_target"        = "s3://${module.trusted_zone_data_source.bucket_id}/unrestricted/llpg/latest_llpg"
    "--enable-glue-datacatalog" = "true"
    "--source_catalog_database" = aws_glue_catalog_database.raw_zone_unrestricted_address_api.name
    "--source_catalog_table"    = "unrestricted_address_api_dbo_hackney_address"

  }
  script_name          = "llpg_latest_to_trusted"
  triggered_by_crawler = aws_glue_crawler.raw_zone_unrestricted_address_api_crawler.name

  crawler_details = {
    database_name      = module.department_unrestricted_data_source.trusted_zone_catalog_database_name
    s3_target_location = "s3://${module.trusted_zone_data_source.bucket_id}/unrestricted/llpg/latest_llpg"
  }

}
