module "active_persons_records_refined" {
  source                         = "../modules/aws-glue-job"
  is_production_environment      = local.is_production_environment
  is_live_environment            = local.is_live_environment
  count = local.is_live_environment && !local.is_production_environment ? 1 : 0

  department                     = module.department_data_and_insight_data_source
  job_name                       = "${local.short_identifier_prefix}Active person records to refined"
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_temp_bucket_id            = module.glue_temp_storage_data_source.bucket_id
  glue_job_worker_type           = "G.1X"
  number_of_workers_for_glue_job = 10
  max_retries                    = 1
  glue_version                   = "3.0"
  glue_job_timeout               = 360
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id

  job_parameters = {
    "--job-bookmark-option"                     = "job-bookmark-enable"
    "--enable-glue-datacatalog"                 = "true"
    "--enable-continuous-cloudwatch-log"        = "true"
    "--additional-python-modules"               = "abydos,graphframes,great_expectations==0.15.48"
    "--source_catalog_database_housing_benefit" = module.department_benefits_and_housing_needs_data_source.raw_zone_catalog_database_name
    "--source_catalog_database_housing"         = module.department_housing_data_source.refined_zone_catalog_database_name
    "--source_catalog_database_parking"         = aws_glue_catalog_database.refined_zone_liberator.name
    "--source_catalog_database_council_tax"     = module.department_revenues_data_source.raw_zone_catalog_database_name

    "--source_catalog_table_person_reshape"            = "person_reshape"
    "--source_catalog_table_tenure_reshape"            = "tenure_reshape"
    "--source_catalog_table_assets_reshape"            = "assets_reshape"
    "--source_catalog_table_ctax_property"             = "lbhaliverbviews_core_ctproperty"
    "--source_catalog_table_ctax_account"              = "lbhaliverbviews_core_ctaccount"
    "--source_catalog_table_ctax_liability_person"     = "lbhaliverbviews_core_ctliab_person"
    "--source_catalog_table_ctax_non_liability_person" = "lbhaliverbviews_core_ctnon_liab"
    "--source_catalog_table_ctax_occupation"           = "lbhaliverbviews_core_ctoccupation"
    "--source_catalog_table_hb_member"                 = "lbhaliverbviews_core_hbmember"
    "--source_catalog_table_hb_tax_calc_stmt"          = "lbhaliverbviews_core_hbctaxcalc_statement"
    "--source_catalog_table_hb_household"              = "lbhaliverbviews_core_hbhousehold"
    "--source_catalog_table_hb_rent_assessment"        = "lbhaliverbviews_core_hbrentass"
    "--source_catalog_table_parking_permit"            = "parking_permit_denormalised_data"
    "--output_path"                                    = "s3://${module.refined_zone_data_source.bucket_id}/data-and-insight/active-person-records/"

  }
  script_name = "active_person_records"

  crawler_details = {
    database_name      = module.department_customer_services_data_source.refined_zone_catalog_database_name
    s3_target_location = "s3://${module.refined_zone_data_source.bucket_id}/data-and-insight/active-person-records"
    configuration      = jsonencode({
      Version  = 1.0
      Grouping = {
        TableLevelConfiguration = 3
      }
    })
  }

}

# Triggers for ingestion
resource "aws_glue_trigger" "active_persons_records_refined_trigger" {
  tags     = module.tags.values
  name     = "${local.short_identifier_prefix}Active Person Records to Refined Ingestion Trigger"
  type     = "SCHEDULED"
  schedule = "cron(0 22 * * ? *)"
  enabled  = local.is_live_environment

  actions {
    job_name = module.active_persons_records_refined.job_name
  }

}

