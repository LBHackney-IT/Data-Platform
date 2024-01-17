locals {
  active_persons_addresses_cleaned_environment_count = local.is_live_environment ? 1 : 0
}

module "active_persons_records_addresses_cleaned_refined" {
  source                         = "../modules/aws-glue-job"
  is_production_environment      = local.is_production_environment
  is_live_environment            = local.is_live_environment
  count                          = local.active_persons_addresses_cleaned_environment_count
  department                     = module.department_data_and_insight_data_source
  job_name                       = "${local.short_identifier_prefix}Active person refined address clean"
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_temp_bucket_id            = module.glue_temp_storage_data_source.bucket_id
  glue_job_worker_type           = "G.1X"
  number_of_workers_for_glue_job = 2
  glue_version                   = "4.0"
  glue_job_timeout               = 360
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id

  job_parameters = {
    "--job-bookmark-option"                           = "job-bookmark-enable"
    "--enable-glue-datacatalog"                       = "true"
    "--enable-continuous-cloudwatch-log"              = "true"
    "--additional-python-modules"                     = "great_expectations==0.15.48"
    "--source_catalog_database_active_person_records" = module.department_data_and_insight_data_source.refined_zone_catalog_database_name

    "--source_catalog_table_active_person_records" = "active_person_records"
    "--output_path"                                = "s3://${module.refined_zone_data_source.bucket_id}/data-and-insight/active-person-records-cleaned-addresses/"

  }
  script_name = "address_cleaning"

  crawler_details = {
    database_name      = module.department_data_and_insight_data_source.refined_zone_catalog_database_name
    s3_target_location = "s3://${module.refined_zone_data_source.bucket_id}/data-and-insight/active-person-records-cleaned-addresses"
    configuration      = null
    table_prefix       = null
  }

}

# Triggers for ingestion
resource "aws_glue_trigger" "active_persons_records_addresses_cleaned_refined_trigger" {
  name     = "${local.short_identifier_prefix}Active Person Records Addresses Cleaned to Refined Ingestion Trigger"
  tags     = module.department_data_and_insight_data_source.tags
  type     = "SCHEDULED"
  schedule = "cron(0 01 * * ? *)"
  enabled  = local.is_production_environment
  count    = local.active_persons_addresses_cleaned_environment_count

  actions {
    job_name = module.active_persons_records_addresses_cleaned_refined[0].job_name
  }

}

