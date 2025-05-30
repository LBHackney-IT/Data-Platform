module "parking_pcn_denormalisation" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_pcn_denormalisation"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_pcn_denormalisation"
  triggered_by_job               = module.parking_pcn_create_event_log.job_name
  job_description                = "This job creates a single de-normalised PCN record with the latest details against it (Events, finance, ETA, etc.). This can then be queried (WITHOUT joins)."
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
    "--conf"                = "spark.sql.legacy.timeParserPolicy=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInWrite=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInWrite=LEGACY"
  }
}

module "parking_persistent_evaders" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_persistent_evaders"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_persistent_evaders"
  triggered_by_job               = module.parking_pcn_denormalisation.job_name
  job_description                = "Job to identify VRM's according to the criteria of Persistent Evaders, and return details of all tickets issued to those VRM's."
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-enable"
    "--environment"         = var.environment
    "--conf"                = "spark.sql.legacy.timeParserPolicy=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInWrite=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInWrite=LEGACY"
  }
}

# Migrated job "parking_school_street_vrms" to dap-airflow om 20/02/2025

# Migrated job "parking_estate_waiting_list_live_permits_type_gds" to dap-airflow om 20/02/2025

# Migrated job "parking_gds_permit_change_comparison" to dap-airflow om 20/02/2025

# Migrated job "parking_kpi_gds_summary" to dap-airflow om 30/05/2025

# Migrated job "parking_foi_pcn_gds_summary" to dap-airflow om 30/05/2025

# Migrated job "parking_permit_denormalised_gds_street_llpg" to dap-airflow om 20/02/2025

module "parking_pcn_create_event_log" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_pcn_create_event_log"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_pcn_create_event_log"
  triggered_by_job               = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description                = "This job reviews the PCN Events trying to find the LATEST event date for a number of Events (i.e. DVLA Requested, DVLA Received). The output is a SINGLE PCN record containing some 30+ fields of Dates. The field name identifies what the date field is"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
    "--conf"                = "spark.sql.legacy.timeParserPolicy=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInWrite=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInWrite=LEGACY"
  }
}

# Migrated job "parking_pcn_report_summary" to dap-airflow om 30/05/2025

# Migrated job "parking_pcn_ltn_report_summary" to dap-airflow om 30/05/2025

# migrated Parking_Suspension_DeNormalised_Data to airflow on 19/05/2025

# migrated Parking_Permit_DeNormalised_Data to airflow on 20/05/2025

# The airflow has the latest version of these 7 tables
# removed Parking_Deployment_Target_Details
# removed parking_ceo_average_on_street
# removed parking_ceo_on_street
# removed parking_ceo_summary
# removed parking_ceo_average_on_street_hrs_mins_secs
# removed parking_percent_street_coverage
# removed parking_percent_street_coverage_cpz

# Migrated "parking_foreign_vrm_pcns" to dap-airflow on 30/05/2025

# Migrated "parking_correspondence_performance_records_with_pcn" to dap-airflow on 30/05/2025

#  parking_Disputes_KPI_GDS_Summary not in use anymore - confirmed with Davina

# Migrated "parking_foi_pcn_gds_daily_summary" to dap-airflow on 30/05/2025

# Migrated "parking_eta_decision_records_pcn_dispute_gds" to dap-airflow on 30/05/2025

# migrated Parking_Permit_diesel_Tends_Bought_in_Month to airflow on 20/05/2025

# Migrated "parking_correspondence_performance_records_with_pcn_gds" to dap-airflow on 30/05/2025

# Migrated "parking_foi_pcn_gds_daily_summary_records" to dap-airflow on 30/05/2025

# Migrated job "parking_correspondence_performance_qa_with_totals_gds" to dap-airflow om 30/05/2025

# Migrated job "parking_defect_met_fail" to dap-airflow om 25/02/2025

# Migrated job "parking_match_pcn_permit_vrm_llpg_nlpg_postcodes" to dap-airflow om 20/02/2025

# Migrated job "parking_defect_met_fail_monthly_format" to dap-airflow om 25/02/2025

# Migrated job parking_permit_street_stress to airflow on 20/05/2025

# migrated parking_permit_street_stress_with_cpz to airflow on 20/05/2025

# Migrated "parking_correspondence_performance_records_with_pcn_downtime" to dap-airflow on 30/05/2025
# Migrated "parking_correspondence_performance_records_with_pcn_downtime_gds" to dap-airflow on 30/05/2025

# Migrated "parking_open_pcns_vrms_linked_cancelled_ringer" to dap-airflow on 30/05/2025

# MRB 15-02-2024 job created
# migrated job "Parking_Suspensions_Processed" to dap-airflow on 19/05/2025
# parking_suspensions_processed_with_finyear migrated to dap-airflow on 19/05/2025

# Migrated "parking_pcn_dvla_response_no_address" to dap-airflow on 30/05/2025

# Migrated job "parking_motorcycle_permits_480" to dap-airflow om 20/02/2025
# Migrated job "parking_permit_street_cpz_stress_mc" to dap-airflow on 21/05/2025


# MRB 18-08-2024 job created
# Migrated job "parking_permit_denormalisation_mc" to dap-airflow om 01/05/2025

# MRB 20-08-2024 job created
# Migrated job "parking_all_suspensions_processed_review" to dap-airflow om 19/05/2025
