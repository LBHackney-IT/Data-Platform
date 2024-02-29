# Ingestion 
module "ingest_vonage_data" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  count = local.is_live_environment ? 1 : 0

  department                      = module.department_customer_services_data_source
  number_of_workers_for_glue_job  = 12
  max_concurrent_runs_of_glue_job = 1
  job_name                        = "${local.short_identifier_prefix}vonage_one_time_ingestion_customer_services"
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  glue_job_worker_type            = "G.2X"
  glue_version                    = "4.0"
  glue_job_timeout                = 360
  job_parameters = {
    "--s3_bucket"          = module.landing_zone_data_source.bucket_id
    "--output_folder_name" = "customer-services/manual/vonage"
    "--secret_name"        = "/customer-services/vonage-key"
    "--api_to_call"        = "stats"
    "--table_to_call"      = "interactions"
  }
  script_name                = "vonage_one_time_ingestion"
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
}
