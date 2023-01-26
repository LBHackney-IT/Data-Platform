# Ingestion
module "ingest_vonage_data" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  count                     = local.is_live_environment && !local.is_production_environment ? 1 : 0

  department                      = "data_and_insight"
  number_of_workers_for_glue_job  = 2
  max_concurrent_runs_of_glue_job = 1
  job_name                        = "${local.short_identifier_prefix}vonage_one_time_ingestion_customer_services"
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  job_parameters = {
    "--s3_bucket"                 = "dataplatform-stg-landing-zone"
    "--output_folder_name"        = "vonage"
    "--secret_name"               = "vonage-key"
    "--api_to_call"               = "stats"
    "--table_to_call"             = "interactions"
    "--number_of_workers"         = 2
  }
  script_name                = "vonage_one_time_ingestion"
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
}