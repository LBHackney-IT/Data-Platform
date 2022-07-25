module "noiseworks_to_raw_zone" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department                 = module.department_env_enforcement_data_source
  job_name                   = "${local.short_identifier_prefix}noiseworks_to_raw_zone"
  helper_module_key          = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key            = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  job_parameters = {
    "--job-bookmark-option"    = "job-bookmark-enable"
    "--s3_bucket_source"       = "s3://${module.noiseworks_data_storage_data_source.bucket_id}/"
    "--s3_bucket_target"       = "s3://${module.raw_zone_data_source.bucket_id}/env-enforcement/noiseworks/"
    "--table_list"             = "Action,User,Complaint,Case,HistoricalCase,Case_perpetrators"
    "--deequ_metrics_location" = "s3://${module.raw_zone_data_source.bucket_id}/quality-metrics/department=env-enforcement/deequ-metrics.json"
  }
  script_name = "noiseworks_copy_csv_to_raw"
  schedule    = "cron(0 2 * * ? *)"

  crawler_details = {
    database_name      = module.department_env_enforcement_data_source.raw_zone_catalog_database_name
    s3_target_location = "s3://${module.raw_zone_data_source.bucket_id}/env-enforcement/noiseworks/"
    table_prefix       = "noiseworks_"
  }
}
