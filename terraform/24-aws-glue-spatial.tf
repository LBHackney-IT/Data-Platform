module "llpg_raw_to_trusted" {
  source = "../modules/aws-glue-job"

  department                 = module.department_unrestricted
  job_name                   = "${local.short_identifier_prefix}llpg_latest_to_trusted"
  glue_job_worker_type       = "G.1X"
  helper_module_key          = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key            = aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage.bucket_id
  job_parameters = {
    "--job-bookmark-option"     = "job-bookmark-enable"
    "--s3_bucket_target"        = "s3://${module.trusted_zone.bucket_id}/unrestricted/llpg/latest_llpg"
    "--enable-glue-datacatalog" = "true"
    "--source_catalog_database" = "dataplatform-stg-raw-zone-unrestricted-address-api" 
    "--source_catalog_table"    = "unrestricted_address_api_dbo_hackney_address"

  }
  script_name      = "llpg_latest_to_trusted"
  triggered_by_job = aws_glue_job.copy_env_enforcement_liberator_landing_to_raw.name

  crawler_details = {
    database_name      = module.department_unrestricted.trusted_zone_catalog_database_name
    s3_target_location = "s3://${module.trusted_zone.bucket_id}/unrestricted/llpg/latest_llpg"
  }

}
