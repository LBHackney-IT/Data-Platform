data "aws_ssm_parameter" "copy_mtfh_reshape_to_refined_crawler_for_HR" {
  name = "/${local.identifier_prefix}/glue_crawler/housing/mtfh_reshape_to_refined_crawler_name"

  depends_on = [
    aws_ssm_parameter.mtfh_reshape_to_refined_crawler_name
  ]
}

module "housing_register_to_refined_and_trusted" {
  source                         = "../modules/aws-glue-job"
  is_production_environment      = local.is_production_environment
  is_live_environment            = local.is_live_environment
  job_name                       = "${local.short_identifier_prefix}Housing Register to refined and trusted"
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_temp_bucket_id            = module.glue_temp_storage_data_source.bucket_id
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  glue_job_worker_type           = "G.1X"
  number_of_workers_for_glue_job = 8
  max_retries                    = 1
  glue_version                   = "4.0"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  job_parameters = {
    "--job-bookmark-option"      = "job-bookmark-enable"
    "--s3_target_refined"        = "s3://${module.refined_zone_data_source.bucket_id}/bens-housing-needs/housing-register"
    "--s3_target_trusted"        = "s3://${module.trusted_zone_data_source.bucket_id}/bens-housing-needs/housing-register"
    "--enable-glue-datacatalog"  = "true"
    "--source_catalog_database"  = module.department_housing_data_source.raw_zone_catalog_database_name
    "--source_catalog_database2" = module.department_unrestricted_data_source.trusted_zone_catalog_database_name
    "--conf"                     = "spark.sql.legacy.timeParserPolicy=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInWrite=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInWrite=LEGACY"
  }
  script_name          = "housing_register_to_refined_and_trusted"
  triggered_by_crawler = data.aws_ssm_parameter.copy_mtfh_reshape_to_refined_crawler_for_HR.value
  tags                 = module.tags.values
}
