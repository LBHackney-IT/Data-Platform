module "housing_apply_gx_dq_tests" {
  source                    = "../modules/aws-glue-job"
  is_production_environment = local.is_production_environment
  is_live_environment       = local.is_live_environment

  count = local.is_live_environment ? 1 : 0

  department                     = module.department_housing_data_source
  job_name                       = "${local.short_identifier_prefix}Housing GX Data Quality Testing"
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_temp_bucket_id            = module.glue_temp_storage_data_source.bucket_id
  glue_job_timeout               = 360
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  trigger_enabled                = local.is_production_environment
  number_of_workers_for_glue_job = 2
  schedule                       = "cron(0 10 ? * MON-FRI *)"
  job_parameters                 = {
    "--job-bookmark-option"              = "job-bookmark-enable"
    "--enable-glue-datacatalog"          = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--additional-python-modules"        = "great_expectations==1.1.0,PyAthena,awswrangler"
    "--region_name"                      = data.aws_region.current.name
    "--s3_endpoint"                      = "https://s3.${data.aws_region.current.name}.amazonaws.com"
    "--s3_target_location"               = "s3://${module.raw_zone_data_source.bucket_id}/housing/data-quality-tests/"
    "--s3_staging_location"              = "s3://${module.athena_storage_data_source.bucket_id}/housing/data-quality-tests/"
    "--target_database"                  = "housing-raw-zone"
    "--target_table"                     = "housing_gx_data_quality_tests"
    "--gx_docs_bucket"                   = module.athena_storage_data_source.bucket_id
    "--gx_docs_prefix"                   = "data-and-insight/anna/glue-dq/data-docs/"
  }

  script_name = "housing_apply_gx_dq_tests"
}
