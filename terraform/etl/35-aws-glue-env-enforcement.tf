


module "liberator_fpns_to_refined" {
  source = "../modules/data-sources/aws-glue-job"

  department                 = module.department_env_enforcement
  job_name                   = "${local.short_identifier_prefix}liberator_fpns_refined"
  glue_job_worker_type       = "G.1X"
  helper_module_key          = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key            = aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage.bucket_id
  job_parameters = {
    "--job-bookmark-option"     = "job-bookmark-enable"
    "--s3_bucket_target"        = "s3://${module.refined_zone.bucket_id}/env-enforcement/fpn_tickets"
    "--s3_bucket_target2"       = "s3://${module.refined_zone.bucket_id}/env-enforcement/fpn_tickets_to_geocode"
    "--enable-glue-datacatalog" = "true"
    "--source_catalog_database" = module.department_env_enforcement.raw_zone_catalog_database_name
    "--source_catalog_table"    = "liberator_fpn_tickets"
    "--source_catalog_table2"   = "liberator_fpn_payments"

  }
  script_name      = "liberator_fpns_refined"
  triggered_by_job = aws_glue_job.copy_env_enforcement_liberator_landing_to_raw.name

  crawler_details = {
    database_name      = module.department_env_enforcement.refined_zone_catalog_database_name
    s3_target_location = "s3://${module.refined_zone.bucket_id}/env-enforcement"
  }

}

module "noisework_complaints_to_refined" {
  source = "../modules/data-sources/aws-glue-job"

  department                 = module.department_env_enforcement
  job_name                   = "${local.short_identifier_prefix}noisework_complaints_to_refined"
  glue_job_worker_type       = "G.1X"
  helper_module_key          = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key            = aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage.bucket_id
  job_parameters = {
    "--job-bookmark-option"     = "job-bookmark-enable"
    "--s3_bucket_target"        = "s3://${module.refined_zone.bucket_id}/env-enforcement/noisework_complaints"
    "--s3_bucket_target2"       = "s3://${module.refined_zone.bucket_id}/env-enforcement/noisework_complaints_to_geocode"
    "--enable-glue-datacatalog" = "true"
    "--source_catalog_database" = module.department_env_enforcement.raw_zone_catalog_database_name
    "--source_catalog_table"    = "noiseworks_case"
    "--source_catalog_table2"   = "noiseworks_complaint"

  }
  script_name          = "noisework_complaints_refined"
  triggered_by_crawler = module.noiseworks_to_raw_zone.crawler_name

  crawler_details = {
    database_name      = module.department_env_enforcement.refined_zone_catalog_database_name
    s3_target_location = "s3://${module.refined_zone.bucket_id}/env-enforcement"
  }

}
