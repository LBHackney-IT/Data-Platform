module "staff_sickness_forecast_refined" {
  source                         = "../modules/aws-glue-job"
  is_production_environment      = local.is_production_environment
  is_live_environment            = local.is_live_environment
  count                          = !local.is_production_environment && local.is_live_environment ? 1 : 0
  department                     = module.department_hr_and_od_data_source
  job_name                       = "${local.short_identifier_prefix}Staff sickness forecasting refined"
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_temp_bucket_id            = module.glue_temp_storage_data_source.bucket_id
  glue_job_worker_type           = "G.1X"
  number_of_workers_for_glue_job = 4
  glue_version                   = "4.0"
  glue_job_timeout               = 360
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id

  job_parameters = {
    "--job-bookmark-option"              = "job-bookmark-enable"
    "--enable-glue-datacatalog"          = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--additional-python-modules"        = "prophet,statsmodels==0.14.0"
    "--source_catalog_database"          = module.department_hr_and_od_data_source.raw_zone_catalog_database_name
    "--source_catalog_table_sickness"    = "staff_sickness"
    "--output_path"                      = "s3://${module.refined_zone_data_source.bucket_id}/hr-and-od/staff-sickness/"
    "--season"                           = 52
    "--periods"                          = 26


  }
  script_name = "staff_sickness_forecasting"

  crawler_details = {
    database_name      = module.department_hr_and_od_data_source.refined_zone_catalog_database_name
    s3_target_location = "s3://${module.refined_zone_data_source.bucket_id}/hr-and-od/staff-sickness/"
    configuration      = null
    table_prefix       = null
    Grouping           = {
      TableLevelConfiguration = 3
    }
  }

}

