module "load_all_academy_data_into_redshift" {
  count                           = local.is_live_environment && !local.is_production_environment ? 1 : 0
  tags  = module.tags.values
  source                          = "../modules/aws-glue-job"
  is_live_environment             = local.is_live_environment
  is_production_environment       = local.is_production_environment
  job_name                        = "${local.short_identifier_prefix}load_all_academy_data_into_redshift"
  script_s3_object_key            = aws_s3_object.load_all_academy_data_into_redshift.key
  pydeequ_zip_key                 = aws_s3_object.pydeequ.key
  helper_module_key               = aws_s3_object.helpers.key
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_temp_bucket_id             = module.glue_temp_storage.bucket_id
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  spark_ui_output_storage_id      = module.spark_ui_output_storage.bucket_id
  glue_version                    = "4.0"
  glue_job_worker_type            = "G.1X"
  number_of_workers_for_glue_job  = 2
  glue_job_timeout                = 220
  schedule                        = "cron(15 7 ? * MON-FRI *)"
  job_parameters = {
    "--additional-python-modules"        = "botocore==1.27.59, redshift_connector==2.1.0"
    "--environment"                      = var.environment
    # This is the ARN of the IAM role used by Redshift Serverless. We have count in redshift-serverless module so we need to use index 0 to get the ARN.
    "--role_arn"                         = try(module.redshift_serverless[0].redshift_serverless_role_arn, "") 
    "--enable-auto-scaling"              = "false"
    "--job-bookmark-option"              = "job-bookmark-disable"
    "--base_s3_url"                      = "${module.raw_zone.bucket_url}/revenues/"
    "--conf"                             = "spark.sql.legacy.timeParserPolicy=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInWrite=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInWrite=LEGACY"
  }
}