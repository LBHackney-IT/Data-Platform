locals {
  housing_mtfh_case_notes_enriched_to_refined_environment_count = local.is_live_environment && !local.is_production_environment ? 1 : 0
}

module "housing_mtfh_case_notes_enriched_to_refined" {
  count                          = local.housing_mtfh_case_notes_enriched_to_refined_environment_count
  source                         = "../modules/aws-glue-job"
  is_production_environment      = local.is_production_environment
  is_live_environment            = local.is_live_environment
  department                     = module.department_housing_data_source
  job_name                       = "${local.short_identifier_prefix}Housing MTFH case notes enriched to refined"
  script_s3_object_key           = aws_s3_object.housing_mtfh_case_notes_enriched_to_refined.key
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_temp_bucket_id            = module.glue_temp_storage_data_source.bucket_id
  glue_job_timeout               = 360
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  number_of_workers_for_glue_job = 2
  glue_job_worker_type           = "G.1X"
  glue_version                   = "3.0"
  job_parameters                 = {
    "--job-bookmark-option"              = "job-bookmark-enable"
    "--enable-glue-datacatalog"          = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--additional-python-modules"        = "great_expectations==0.15.48,spacy==3.7.4"
    "--s3_source_mtfh_notes"             = module.department_housing_data_source.raw_zone_catalog_database_name
    "--source_table_mtfh_notes"          = "mtfh_notes"
    "--s3_source_tenure"                 = module.department_housing_data_source.refined_zone_catalog_database_name
    "--source_table_tenure"              = "tenure_reshape"
    "--s3_output_path"                   = "s3://${module.refined_zone_data_source.bucket_id}/housing/mtfh-case-notes-enriched/"

  }
}

# Triggers for ingestion
resource "aws_glue_trigger" "housing_mtfh_case_notes_enriched_to_refined_trigger" {
  name     = "${local.short_identifier_prefix}Housing MTFH case notes enrichment to refined trigger"
  tags     = module.department_housing_data_source.tags
  type     = "SCHEDULED"
  schedule = "cron(0 10 * * ? *)"
  enabled  = local.is_production_environment
  count    = local.housing_mtfh_case_notes_enriched_to_refined_environment_count

  actions {
    job_name = module.housing_mtfh_case_notes_enriched_to_refined[0].job_name
  }

}

crawler_details = {
  database_name      = module.department_housing_data_source.refined_zone_catalog_database_name
  name               = "${local.short_identifier_prefix}Housing MTFH case notes enrichment to refined"
  role               = data.aws_iam_role.glue_role.arn
  s3_target_location = "s3://${module.refined_zone_data_source.bucket_id}/housing/mtfh-case-notes-enriched/"
  tags               = module.tags.values
  configuration      = jsonencode({
    Version  = 1.0
    Grouping = {
      TableLevelConfiguration = 8
    }
  })

}

