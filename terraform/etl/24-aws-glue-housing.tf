data "aws_ssm_parameter" "copy_mtfh_dynamo_db_tables_to_raw_zone_crawler" {
  name = "/${local.identifier_prefix}/glue_crawler/housing/copy_mtfh_dynamo_db_tables_to_raw_zone_crawler_name"
}

module "mtfh_reshape_to_refined" {
  source = "../modules/aws-glue-job"

  department                 = module.department_housing_data_source
  job_name                   = "${local.short_identifier_prefix}MTFH reshape to refined"
  glue_job_worker_type       = "Standard"
  helper_module_key          = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key            = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  job_parameters = {
    "--job-bookmark-option"     = "job-bookmark-enable"
    "--s3_bucket_target"        = "s3://${module.refined_zone_data_source.bucket_id}/housing/mtfh"
    "--enable-glue-datacatalog" = "true"
    "--source_catalog_database" = module.department_housing_data_source.raw_zone_catalog_database_name
  }
  script_name          = "housing_mtfh_reshape_to_refined"
  triggered_by_crawler = data.aws_ssm_parameter.copy_mtfh_dynamo_db_tables_to_raw_zone_crawler.value
  crawler_details = {
    database_name      = module.department_housing_data_source.refined_zone_catalog_database_name
    s3_target_location = "s3://${module.refined_zone_data_source.bucket_id}/housing/mtfh"
  }

}
