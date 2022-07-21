


module "liberator_fpns_to_refined" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department                 = module.department_env_enforcement_data_source
  job_name                   = "${local.short_identifier_prefix}liberator_fpns_refined"
  glue_job_worker_type       = "G.1X"
  helper_module_key          = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key            = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  job_parameters = {
    "--job-bookmark-option"     = "job-bookmark-enable"
    "--s3_bucket_target"        = "s3://${module.refined_zone_data_source.bucket_id}/env-enforcement/fpn_tickets"
    "--s3_bucket_target2"       = "s3://${module.refined_zone_data_source.bucket_id}/env-enforcement/fpn_tickets_to_geocode"
    "--enable-glue-datacatalog" = "true"
    "--source_catalog_database" = module.department_env_enforcement_data_source.raw_zone_catalog_database_name
    "--source_catalog_table"    = "liberator_fpn_tickets"
    "--source_catalog_table2"   = "liberator_fpn_payments"

  }
  script_name      = "liberator_fpns_refined"
  triggered_by_job = "${local.short_identifier_prefix}Copy Env Enforcement Liberator landing zone to raw"

  crawler_details = {
    database_name      = module.department_env_enforcement_data_source.refined_zone_catalog_database_name
    s3_target_location = "s3://${module.refined_zone_data_source.bucket_id}/env-enforcement"
  }

}

module "noisework_complaints_to_refined" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department                 = module.department_env_enforcement_data_source
  job_name                   = "${local.short_identifier_prefix}noisework_complaints_to_refined"
  glue_job_worker_type       = "G.1X"
  helper_module_key          = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key            = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  job_parameters = {
    "--job-bookmark-option"     = "job-bookmark-enable"
    "--s3_bucket_target"        = "s3://${module.refined_zone_data_source.bucket_id}/env-enforcement/noisework_complaints"
    "--s3_bucket_target2"       = "s3://${module.refined_zone_data_source.bucket_id}/env-enforcement/noisework_complaints_to_geocode"
    "--enable-glue-datacatalog" = "true"
    "--source_catalog_database" = module.department_env_enforcement_data_source.raw_zone_catalog_database_name
    "--source_catalog_table"    = "noiseworks_case"
    "--source_catalog_table2"   = "noiseworks_complaint"

  }
  script_name          = "noisework_complaints_refined"
  triggered_by_crawler = module.noiseworks_to_raw_zone.crawler_name

  crawler_details = {
    database_name      = module.department_env_enforcement_data_source.refined_zone_catalog_database_name
    s3_target_location = "s3://${module.refined_zone_data_source.bucket_id}/env-enforcement"
  }

}
