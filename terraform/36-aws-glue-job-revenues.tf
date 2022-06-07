module "etl_ctax_live_properties" {
  source                         = "../modules/aws-glue-job"
  department                     = module.department_revenues
  job_name                       = "${local.short_identifier_prefix}etl_ctax_live_properties"
  helper_module_key              = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
  script_name                    = "etl_ctax_live_properties"
  job_description                = "Created with AWS Glue Studio: Revenues ETL CTax_Live_Properties_Automation"
  schedule                       = "cron(55 9 ? * MON-FRI *)"
  glue_job_worker_type           = "G.2X"
  number_of_workers_for_glue_job = 10
  glue_job_timeout               = 1440
  spark_ui_output_storage_id     = module.spark_ui_output_storage.bucket_id
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

module "etl_zerobase_ctax_live_properties" {
  source                         = "../modules/aws-glue-job"
  department                     = module.department_revenues
  job_name                       = "${local.short_identifier_prefix}etl_zerobase_ctax_live_properties"
  helper_module_key              = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
  script_name                    = "etl_zerobase_ctax_live_properties"
  job_description                = "Created with AWS Glue Studio: Revenues ETL CTax_Live_Properties_Initialization"
  schedule                       = "cron(0 19 7 JUN ? 2022)"
  glue_job_worker_type           = "G.2X"
  number_of_workers_for_glue_job = 10
  glue_job_timeout               = 1440
  spark_ui_output_storage_id     = module.spark_ui_output_storage.bucket_id
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}
