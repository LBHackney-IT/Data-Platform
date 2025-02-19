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

# Migrated job "parking_school_street_vrms" to dap-airflow om 19/02/2025

# Migrated job "parking_estate_waiting_list_live_permits_type_gds" to dap-airflow om 19/02/2025

# Migrated job "parking_gds_permit_change_comparison" to dap-airflow om 19/02/2025

module "parking_kpi_gds_summary" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_kpi_gds_summary"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_kpi_gds_summary"
  triggered_by_job               = module.parking_pcn_denormalisation.job_name
  job_description                = "Summarising data from the FOI Summary table to be used in Google Data Studio as need to be under 100,000"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  glue_job_timeout               = 240
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
    "--conf"                = "spark.sql.legacy.timeParserPolicy=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInWrite=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInWrite=LEGACY"
  }
}

module "parking_foi_pcn_gds_summary" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_foi_pcn_gds_summary"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_foi_pcn_gds_summary"
  triggered_by_job               = module.parking_pcn_denormalisation.job_name
  job_description                = "Summarising data from the FOI Google Data Studio dashboard as need to be under 100,000 -"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  glue_job_timeout               = 240
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
    "--conf"                = "spark.sql.legacy.timeParserPolicy=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInWrite=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInWrite=LEGACY"
  }
}

# Migrated job "parking_permit_denormalised_gds_street_llpg" to dap-airflow om 19/02/2025

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

module "parking_pcn_report_summary" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_pcn_report_summary"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_pcn_report_summary"
  triggered_by_job               = module.parking_pcn_denormalisation.job_name
  job_description                = "This job creates the % return figures for the Bailiff data"
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

module "parking_pcn_ltn_report_summary" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_pcn_ltn_report_summary"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_pcn_ltn_report_summary"
  triggered_by_job               = module.parking_pcn_denormalisation.job_name
  job_description                = "This job creates the LTN PCN count and Total paid"
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

module "parking_suspension_de-normalised_data" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_suspension_de-normalised_data"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_suspension_de-normalised_data"
  triggered_by_job               = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description                = "This job creates the Suspension de-normalised data"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}


module "parking_permit_de_normalisation" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_permit_de_normalisation"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_permit_de_normalisation"
  triggered_by_job               = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description                = "This job creates the Permit de-normalised data"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}


module "parking_ceo_on_street" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_ceo_on_street"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_ceo_on_street"
  triggered_by_job               = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description                = "This job creates the Permit de-normalised data"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

module "parking_ceo_summary" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_ceo_summary"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_ceo_summary"
  triggered_by_job               = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description                = "This job creates the Permit de-normalised data"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

module "parking_deployment_target_details" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_deployment_target_details"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_deployment_target_details"
  triggered_by_job               = module.parking_ceo_on_street.job_name
  job_description                = "This job creates the Permit de-normalised data"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

module "parking_ceo_average_on_street" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_ceo_average_on_street"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_ceo_average_on_street"
  triggered_by_job               = module.parking_ceo_on_street.job_name
  job_description                = "This job creates the Permit de-normalised data"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-enable"
    "--environment"         = var.environment
  }
}

module "parking_percent_street_coverage" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_percent_street_coverage"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_percent_street_coverage"
  triggered_by_job               = module.parking_deployment_target_details.job_name
  job_description                = "This job creates the Permit de-normalised data"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

module "parking_ceo_average_on_street_hrs_mins_secs" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_ceo_average_on_street_hrs_mins_secs"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_ceo_average_on_street_hrs_mins_secs"
  triggered_by_job               = module.parking_ceo_on_street.job_name
  job_description                = "This job creates the Permit de-normalised data"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

module "parking_percent_street_coverage_cpz" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_percent_street_coverage_cpz"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_percent_street_coverage_cpz"
  triggered_by_job               = module.parking_deployment_target_details.job_name
  job_description                = "This job creates the Permit de-normalised data"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

module "parking_foreign_vrm_pcns" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_foreign_vrm_pcns"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_foreign_vrm_pcns"
  triggered_by_job               = module.parking_pcn_denormalisation.job_name
  job_description                = "This job creates the LTN PCN count and Total paid"
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


module "parking_correspondence_performance_records_with_pcn" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_correspondence_performance_records_with_pcn"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_correspondence_performance_records_with_pcn"
  triggered_by_job               = module.parking_pcn_denormalisation.job_name
  job_description                = "correspondence performance records with pcn"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  trigger_enabled                = local.is_production_environment
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
    "--conf"                = "spark.sql.legacy.timeParserPolicy=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInWrite=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInWrite=LEGACY"
  }
}

module "parking_disputes_kpi_gds_summary" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_disputes_kpi_gds_summary"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_disputes_kpi_gds_summary"
  job_description                = "Disputes and responses for KPI reporting in Google Data Studio (GDS) summary"
  trigger_enabled                = false
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}
module "parking_foi_pcn_gds_daily_summary" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_foi_pcn_gds_daily_summary"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_foi_pcn_gds_daily_summary"
  triggered_by_job               = module.parking_pcn_denormalisation.job_name
  job_description                = "Daily summarising data from the FOI Google Data Studio dashboard as need to be under 100,000"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  trigger_enabled                = local.is_production_environment
  glue_job_timeout               = 240
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
    "--conf"                = "spark.sql.legacy.timeParserPolicy=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInWrite=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInWrite=LEGACY --conf spark.sql.legacy.ctePrecedencePolicy=LEGACY"
  }
}
module "parking_eta_decision_records_pcn_dispute_gds" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_eta_decision_records_pcn_dispute_gds"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_eta_decision_records_pcn_dispute_gds"
  triggered_by_job               = module.parking_pcn_denormalisation.job_name
  job_description                = "Daily summarising data from the FOI Google Data Studio dashboard as need to be under 100,000"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  trigger_enabled                = local.is_production_environment
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

# MRB 08-08-2022 Job created
module "Parking_Permit_Diesel_Trends_Bought_in_Month" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}Parking_Permit_Diesel_Trends_Bought_in_Month"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_permit_diesel_trends_bought_in_month"
  job_description                = "Monthly review of Permits bought in month, broken down by diesel or electric vehicles"
  trigger_enabled                = local.is_production_environment
  schedule                       = "cron(0 1 10 * ? *)"
  number_of_workers_for_glue_job = 6
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}
module "parking_correspondence_performance_records_with_pcn_gds" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_correspondence_performance_records_with_pcn_gds"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_correspondence_performance_records_with_pcn_gds"
  triggered_by_job               = module.parking_pcn_denormalisation.job_name
  job_description                = "parking_correspondence_performance_records_with_pcn with no timestamp for GDS"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  trigger_enabled                = local.is_production_environment
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
    "--conf"                = "spark.sql.legacy.timeParserPolicy=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInWrite=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInWrite=LEGACY"
  }
}


module "parking_foi_pcn_gds_daily_summary_records" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_foi_pcn_gds_daily_summary_records"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_foi_pcn_gds_daily_summary_records"
  triggered_by_job               = module.parking_pcn_denormalisation.job_name
  job_description                = "Records of daily summarising data from the FOI Google Data Studio dashboard as need to be under 100,000"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  trigger_enabled                = local.is_production_environment
  glue_job_timeout               = 240
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
    "--conf"                = "spark.sql.legacy.timeParserPolicy=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInWrite=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInWrite=LEGACY --conf spark.sql.legacy.ctePrecedencePolicy=LEGACY"
  }
}


module "parking_correspondence_performance_qa_with_totals_gds" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_correspondence_performance_qa_with_totals_gds"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_correspondence_performance_qa_with_totals_gds"
  triggered_by_job               = "${local.short_identifier_prefix}parking_correspondence_performance_records_with_pcn"
  job_description                = "For use in Google Studio to calculate the Correspondence performance for each calendar month Total number of cases and Total number of QA reviews for each month."
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  trigger_enabled                = local.is_production_environment
  glue_job_timeout               = 240
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
    "--conf"                = "spark.sql.legacy.timeParserPolicy=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInWrite=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInWrite=LEGACY"
  }
}

# MRB 22-11-2022 Job created
module "parking_defect_met_fail" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_defect_met_fail"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_defect_met_fail"
  triggered_by_crawler           = local.is_live_environment ? aws_glue_crawler.google_sheet_ingestion_raw_zone["parking"].name : null
  job_description                = "To collect and format the Ops Defect Data."
  trigger_enabled                = local.is_production_environment
  glue_job_timeout               = 10
  number_of_workers_for_glue_job = 2
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

# Migrated job "parking_match_pcn_permit_vrm_llpg_nlpg_postcodes" to dap-airflow om 19/02/2025

# MRB 17-04-2023 Job created
module "parking_defect_met_fail_monthly_format" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_defect_met_fail_monthly_format"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_defect_met_fail_monthly_format"
  triggered_by_crawler           = local.is_live_environment ? aws_glue_crawler.google_sheet_ingestion_raw_zone["parking"].name : null
  job_description                = "To collect and format the Ops Defect Data into a Pivot."
  trigger_enabled                = local.is_production_environment
  glue_job_timeout               = 10
  number_of_workers_for_glue_job = 2
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}


# MRB 17-07-2023 Job created
module "parking_permit_street_stress" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_permit_street_stress"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_permit_street_stress"
  triggered_by_job               = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description                = "Calculate Permit stress, by Street and Permit Type"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  trigger_enabled                = local.is_production_environment
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}
# MRB 14-08-2023 Job created
module "parking_permit_street_stress_with_cpz" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_permit_street_stress_with_cpz"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_permit_street_stress_with_cpz"
  triggered_by_job               = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description                = "Calculate Permit stress, by Street and Permit Type"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  trigger_enabled                = local.is_production_environment
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}
module "parking_correspondence_performance_records_with_pcn_downtime" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_correspondence_performance_records_with_pcn_downtime"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_correspondence_performance_records_with_pcn_downtime"
  triggered_by_job               = module.parking_pcn_denormalisation.job_name
  job_description                = "correspondence performance records with pcn FOI records Team details and Downtime data"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  trigger_enabled                = local.is_production_environment
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
    "--conf"                = "spark.sql.legacy.timeParserPolicy=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInWrite=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInWrite=LEGACY"
  }
}

module "parking_correspondence_performance_records_with_pcn_downtime_gds" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_correspondence_performance_records_with_pcn_downtime_gds"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_correspondence_performance_records_with_pcn_downtime_gds"
  triggered_by_job               = module.parking_pcn_denormalisation.job_name
  job_description                = "correspondence performance records with pcn FOI records Team details and Downtime data for Google Studio - gds"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  trigger_enabled                = local.is_production_environment
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
    "--conf"                = "spark.sql.legacy.timeParserPolicy=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInWrite=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInWrite=LEGACY"
  }
}

module "parking_open_pcns_vrms_linked_cancelled_ringer" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_open_pcns_vrms_linked_cancelled_ringer"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_open_pcns_vrms_linked_cancelled_ringer"
  triggered_by_job               = module.parking_pcn_denormalisation.job_name
  job_description                = "Parking Open PCNs linked to VRMs cancelled due to being a Ringer or Clone"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  trigger_enabled                = local.is_production_environment
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
    "--conf"                = "spark.sql.legacy.timeParserPolicy=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInWrite=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInWrite=LEGACY"
  }
}
# MRB 15-02-2024 job created
module "parking_suspensions_processed" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_suspensions_processed"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_suspensions_processed"
  triggered_by_job               = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description                = "format suspensions processed"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  trigger_enabled                = local.is_production_environment
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
    "--conf"                = "spark.sql.legacy.timeParserPolicy=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInWrite=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInWrite=LEGACY"
  }
}
# MRB 15-02-2024 job created
module "parking_suspensions_processed_with_finyear" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_suspensions_processed_with_finyear"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_suspensions_processed_with_finyear"
  triggered_by_job               = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description                = "format suspensions processed within financial year"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  trigger_enabled                = local.is_production_environment
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
    "--conf"                = "spark.sql.legacy.timeParserPolicy=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInWrite=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInWrite=LEGACY"
  }
}

module "parking_pcn_dvla_response_no_address" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_pcn_dvla_response_no_address"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_pcn_dvla_response_no_address"
  triggered_by_job               = module.parking_pcn_denormalisation.job_name
  job_description                = "All VRMs with PCNs response from DVLA has no address still open and not due to be written off"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  trigger_enabled                = local.is_production_environment
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
    "--conf"                = "spark.sql.legacy.timeParserPolicy=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInWrite=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInWrite=LEGACY"
  }
}

# Migrated job "parking_motorcycle_permits_480" to dap-airflow om 19/02/2025

module "parking_permit_street_cpz_stress_mc" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_permit_street_cpz_stress_mc"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_permit_street_cpz_stress_mc"
  triggered_by_job               = module.parking_permit_de_normalisation.job_name
  job_description                = "A new way for Mike to get the parking_permit_street_cpz_stress_mc data"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  trigger_enabled                = local.is_production_environment
  number_of_workers_for_glue_job = 2 # 2 minimum which is enough for this job
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
    "--conf"                = "spark.sql.legacy.timeParserPolicy=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInWrite=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInWrite=LEGACY"
  }
}
# MRB 18-08-2024 job created
module "parking_permit_denormalisation_mc" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_permit_denormalisation_mc"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_permit_denormalisation_mc"
  triggered_by_job               = module.parking_permit_de_normalisation.job_name
  job_description                = "Permit denormalisation update to include a Motorcycle flag"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  trigger_enabled                = local.is_production_environment
  number_of_workers_for_glue_job = 2 # 2 minimum which is enough for this job
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
    "--conf"                = "spark.sql.legacy.timeParserPolicy=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInWrite=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInWrite=LEGACY"
  }
}

# MRB 20-08-2024 job created
module "parking_all_suspensions_processed_review" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_all_suspensions_processed_review"
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_all_suspensions_processed_review"
  triggered_by_job               = module.parking_suspension_de-normalised_data.job_name
  job_description                = "Review of all Suspension records"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  trigger_enabled                = local.is_production_environment
  number_of_workers_for_glue_job = 2 # 2 minimum which is enough for this job
  glue_job_worker_type           = "G.1X"
  glue_version                   = "4.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
    "--conf"                = "spark.sql.legacy.timeParserPolicy=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInWrite=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInWrite=LEGACY"
  }
}
