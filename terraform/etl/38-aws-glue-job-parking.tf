module "parking_pcn_denormalisation" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_pcn_denormalisation"
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_pcn_denormalisation"
  triggered_by_job               = module.parking_pcn_create_event_log.job_name
  job_description                = "This job creates a single de-normalised PCN record with the latest details against it (Events, finance, ETA, etc.). This can then be queried (WITHOUT joins)."
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

module "parking_persistent_evaders" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_persistent_evaders"
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_persistent_evaders"
  triggered_by_job               = module.parking_pcn_denormalisation.job_name
  job_description                = "Job to identify VRM's according to the criteria of Persistent Evaders, and return details of all tickets issued to those VRM's."
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-enable"
    "--environment"         = var.environment
  }
}

module "parking_school_street_vrms" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_school_street_vrms"
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_school_street_vrms"
  triggered_by_job               = module.parking_permit_denormalised_gds_street_llpg.job_name
  job_description                = "Permit changes comparison - compare changes in permits from the parking_permit_denormalised_gds_street_llpg table to be used in google data studio  Compares latest import to previous import in table"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

module "parking_estate_waiting_list_live_permits_type_gds" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_estate_waiting_list_live_permits_type_gds"
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_estate_waiting_list_live_permits_type_gds"
  triggered_by_job               = module.parking_permit_denormalised_gds_street_llpg.job_name
  job_description                = "Filters for distinct record id's and adds number of Live permits by type.  This is for use by Parking Permits team."
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

module "parking_gds_permit_change_comparison" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_gds_permit_change_comparison"
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_gds_permit_change_comparison"
  triggered_by_job               = module.parking_permit_denormalised_gds_street_llpg.job_name
  job_description                = "Permit changes comparison - compare changes in permits from the parking_permit_denormalised_gds_street_llpg table to be used in google data studio  Compares latest import to previous import in table"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "3.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

module "parking_kpi_gds_summary" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_kpi_gds_summary"
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_kpi_gds_summary"
  triggered_by_job               = module.parking_pcn_denormalisation.job_name
  job_description                = "Summarising data from the FOI Summary table to be used in Google Data Studio as need to be under 100,000"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_job_timeout               = 240
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

module "parking_foi_pcn_gds_summary" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_foi_pcn_gds_summary"
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_foi_pcn_gds_summary"
  triggered_by_job               = module.parking_pcn_denormalisation.job_name
  job_description                = "Summarising data from the FOI Google Data Studio dashboard as need to be under 100,000 -"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_job_timeout               = 240
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

module "parking_permit_denormalised_gds_street_llpg" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_permit_denormalised_gds_street_llpg"
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_permit_denormalised_gds_street_llpg"
  triggered_by_job               = module.parking_permit_de_normalisation.job_name
  job_description                = "parking_permit_denormalised_data and bolts on fields from llpg (usrn, Street record street name, street_description, ward code, ward name, property_shell, blpu_class, usage_primary, usage_description, planning_use_class, longitude & latitude) to be used in gds(Google Data Studio)"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

module "parking_reps_and_appeals_correspondance_kpi_gds_summary" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_reps_and_appeals_correspondance_kpi_gds_summary"
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_reps_and_appeals_correspondance_kpi_gds_summary"
  triggered_by_job               = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description                = "Reps & Appeals correspondence KPI GDS summary"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

module "parking_reps_and_appeals_correspondance_kpi_gds_summary_qtr" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_reps_and_appeals_correspondance_kpi_gds_summary_qtr"
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_reps_and_appeals_correspondance_kpi_gds_summary_qtr"
  triggered_by_job               = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description                = "Reps & Appeals correspondence KPI GDS summary by Quarters"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

module "parking_vouchers_approved_summary_gds" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_vouchers_approved_summary_gds"
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_vouchers_approved_summary_gds"
  triggered_by_job               = module.parking_dc_liberator_latest_permit_status.job_name
  job_description                = "Summary of voucher applications approved by FY, Month year, cpz and cpz name for use in GDS"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

module "parking_bailiff_allocation" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_bailiff_allocation"
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_bailiff_allocation"
  triggered_by_job               = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description                = "This job creates the % return figures for the Bailiff data"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

module "parking_bailiff_ea_warrant_total" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_bailiff_ea_warrant_total"
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_bailiff_ea_warrant_total"
  triggered_by_job               = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description                = "This job creates the % return figures for the Bailiff data"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

module "parking_bailiff_return" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_bailiff_return"
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_bailiff_return"
  triggered_by_job               = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description                = "This job creates the % return figures for the Bailiff data"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

module "parking_pcn_create_event_log" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_pcn_create_event_log"
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_pcn_create_event_log"
  triggered_by_job               = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description                = "This job reviews the PCN Events trying to find the LATEST event date for a number of Events (i.e. DVLA Requested, DVLA Received). The output is a SINGLE PCN record containing some 30+ fields of Dates. The field name identifies what the date field is"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

module "parking_pcn_report_summary" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_pcn_report_summary"
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_pcn_report_summary"
  triggered_by_job               = module.parking_pcn_denormalisation.job_name
  job_description                = "This job creates the % return figures for the Bailiff data"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

module "parking_pcn_ltn_report_summary" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_pcn_ltn_report_summary"
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_pcn_ltn_report_summary"
  triggered_by_job               = module.parking_pcn_denormalisation.job_name
  job_description                = "This job creates the LTN PCN count and Total paid"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-enable"
    "--environment"         = var.environment
  }
}

module "parking_suspension_de-normalised_data" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_suspension_de-normalised_data"
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_suspension_de-normalised_data"
  triggered_by_job               = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description                = "This job creates the Suspension de-normalised data"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

module "parking_cycle_hangars_denormalisation" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_cycle_hangars_denormalisation"
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_cycle_hangars_denormalisation"
  triggered_by_job               = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description                = "denormalisation and deduplication of cycle hangars extracts"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

module "parking_reps_and_appeals_correspondance" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_reps_and_appeals_correspondance"
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_reps_and_appeals_correspondance"
  triggered_by_job               = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description                = "Reps & Appeals correspondence KPI"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
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
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_permit_de_normalisation"
  triggered_by_job               = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description                = "This job creates the Permit de-normalised data"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

module "parking_cedar_payments" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_cedar_payments"
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_cedar_payments"
  triggered_by_job               = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description                = "This job creates the % return figures for the Bailiff data"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

module "parking_cedar_fulling_total_summary" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_cedar_fulling_total_summary"
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_cedar_fulling_total_summary"
  triggered_by_job               = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description                = "This job creates the % return figures for the Bailiff data"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
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
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_ceo_on_street"
  triggered_by_job               = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description                = "This job creates the Permit de-normalised data"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
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
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_ceo_summary"
  triggered_by_job               = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description                = "This job creates the Permit de-normalised data"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
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
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_deployment_target_details"
  triggered_by_job               = module.parking_ceo_on_street.job_name
  job_description                = "This job creates the Permit de-normalised data"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
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
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_ceo_average_on_street"
  triggered_by_job               = module.parking_ceo_on_street.job_name
  job_description                = "This job creates the Permit de-normalised data"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
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
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_percent_street_coverage"
  triggered_by_job               = module.parking_deployment_target_details.job_name
  job_description                = "This job creates the Permit de-normalised data"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

module "parking_bailiff_warrant_figures" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_bailiff_warrant_figures"
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_bailiff_warrant_figures"
  triggered_by_job               = module.parking_pcn_denormalisation.job_name
  job_description                = "This job creates the Permit de-normalised data"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

module "parking_markets_denormalisation" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_markets_denormalisation"
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_markets_denormalisation"
  triggered_by_job               = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description                = "This job creates the % return figures for the Bailiff data"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
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
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_ceo_average_on_street_hrs_mins_secs"
  triggered_by_job               = module.parking_ceo_on_street.job_name
  job_description                = "This job creates the Permit de-normalised data"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

module "parking_market_licence_totals" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_market_licence_totals"
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_market_licence_totals"
  triggered_by_job               = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description                = "This job creates the Permit de-normalised data"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

module "parking_cedar_backing_data_summary" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_cedar_backing_data_summary"
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_cedar_backing_data_summary"
  triggered_by_job               = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description                = "This job creates the % return figures for the Bailiff data"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
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
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_percent_street_coverage_cpz"
  triggered_by_job               = module.parking_deployment_target_details.job_name
  job_description                = "This job creates the Permit de-normalised data"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
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
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_foreign_vrm_pcns"
  triggered_by_job               = module.parking_pcn_denormalisation.job_name
  job_description                = "This job creates the LTN PCN count and Total paid"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-enable"
    "--environment"         = var.environment
  }
}

module "parking_voucher_de_normalised" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_voucher_de_normalised"
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_voucher_de_normalised"
  triggered_by_job               = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description                = "Permit changes comparison - compare changes in permits from the parking_permit_denormalised_gds_street_llpg table to be used in google data studio  Compares latest import to previous import in table"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}
module "parking_correspondence_performance_records_with_pcn" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_correspondence_performance_records_with_pcn"
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_correspondence_performance_records_with_pcn"
  glue_version                   = "3.0"
  triggered_by_job               = module.parking_pcn_denormalisation.job_name
  job_description                = "correspondence performance records with pcn"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  trigger_enabled                = local.is_production_environment
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}
module "parking_dc_liberator_latest_permit_status" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_dc_liberator_latest_permit_status"
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_dc_liberator_latest_permit_status"
  glue_version                   = "3.0"
  triggered_by_job               = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description                = "Parking Latest permit status from the Liberator Landing zone permit status table."
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  trigger_enabled                = local.is_production_environment
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}
module "parking_disputes_kpi_gds_summary" {
  source                     = "../modules/aws-glue-job"
  is_live_environment        = local.is_live_environment
  is_production_environment  = local.is_production_environment
  department                 = module.department_parking_data_source
  job_name                   = "${local.short_identifier_prefix}parking_disputes_kpi_gds_summary"
  helper_module_key          = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key            = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  script_name                = "parking_disputes_kpi_gds_summary"
  glue_version               = "3.0"
  #  triggered_by_job           = "${local.short_identifier_prefix}parking_pcn_denormalisation"
  job_description = "Disputes and responses for KPI reporting in Google Data Studio (GDS) summary"
  #  workflow_name              = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  trigger_enabled                = false
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
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
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_foi_pcn_gds_daily_summary"
  triggered_by_job               = module.parking_pcn_denormalisation.job_name
  job_description                = "Daily summarising data from the FOI Google Data Studio dashboard as need to be under 100,000"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  trigger_enabled                = local.is_production_environment
  glue_job_timeout               = 240
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}
module "parking_eta_decision_records_pcn_dispute_gds" {
  source                     = "../modules/aws-glue-job"
  is_live_environment        = local.is_live_environment
  is_production_environment  = local.is_production_environment
  department                 = module.department_parking_data_source
  job_name                   = "${local.short_identifier_prefix}parking_eta_decision_records_pcn_dispute_gds"
  helper_module_key          = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key            = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  script_name                = "parking_eta_decision_records_pcn_dispute_gds"
  glue_version               = "3.0"
  #  triggered_by_job           = "${local.short_identifier_prefix}parking_pcn_denormalisation"
  job_description = "Daily summarising data from the FOI Google Data Studio dashboard as need to be under 100,000"
  #  workflow_name              = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  trigger_enabled                = false
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}
module "parking_dc_liberator_permit_llpg_street_records" {
  source                     = "../modules/aws-glue-job"
  is_live_environment        = local.is_live_environment
  is_production_environment  = local.is_production_environment
  department                 = module.department_parking_data_source
  job_name                   = "${local.short_identifier_prefix}parking_dc_liberator_permit_llpg_street_records"
  helper_module_key          = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key            = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  script_name                = "parking_dc_liberator_permit_llpg_street_records"
  glue_version               = "3.0"
  # triggered_by_job           = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description = "Street records for the permit llpg table in the liberator raw zone"
  # workflow_name              = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  trigger_enabled                = false
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}

# MRB 22-07-2022 Job created
module "parking_visitor_voucher_qtrly_review" {
  source                     = "../modules/aws-glue-job"
  is_live_environment        = local.is_live_environment
  is_production_environment  = local.is_production_environment
  department                 = module.department_parking_data_source
  job_name                   = "${local.short_identifier_prefix}parking_visitor_voucher_qtrly_review"
  helper_module_key          = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key            = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  script_name                = "parking_visitor_voucher_qtrly_review"
  #  triggered_by_job           = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description = "Quarterly review of Visitor Voucher sales"
  #  workflow_name              = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  trigger_enabled                = local.is_production_environment
  schedule                       = "cron(0 1 10 * ? *)"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "3.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}
# MRB 25-07-2022 Job created   
module "Parking_Ringgo_Review-copy" {
  source                     = "../modules/aws-glue-job"
  is_live_environment        = local.is_live_environment
  is_production_environment  = local.is_production_environment
  department                 = module.department_parking_data_source
  job_name                   = "${local.short_identifier_prefix}Parking_Ringgo_Review-copy"
  helper_module_key          = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key            = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  script_name                = "parking_ringgo_review-copy"
  #  triggered_by_job           = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description = "Quarterly review of Ringgo sessions"
  #  workflow_name              = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  trigger_enabled                = local.is_production_environment
  schedule                       = "cron(0 1 10 * ? *)"
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  glue_version                   = "3.0"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}
# MRB 08-08-2022 Job created   
module "Parking_Permit_Diesel_Tends_Bought_in_Month" {
  source                     = "../modules/aws-glue-job"
  is_live_environment        = local.is_live_environment
  is_production_environment  = local.is_production_environment
  department                 = module.department_parking_data_source
  job_name                   = "${local.short_identifier_prefix}Parking_Permit_Diesel_Tends_Bought_in_Month"
  helper_module_key          = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key            = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  script_name                = "parking_permit_diesel_tends_bought_in_month"
  #  triggered_by_job           = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  job_description = "Monthly review of Permits bought in month, broken down by diesel or electric vehicles"
  #  workflow_name              = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  trigger_enabled                = local.is_production_environment
  schedule                       = "cron(0 1 10 * ? *)"
  number_of_workers_for_glue_job = 2
  glue_job_worker_type           = "G.1X"
  glue_version                   = "3.0"
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
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_correspondence_performance_records_with_pcn_gds"
  glue_version                   = "3.0"
  triggered_by_job               = module.parking_pcn_denormalisation.job_name
  job_description                = "parking_correspondence_performance_records_with_pcn with no timestamp for GDS"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  trigger_enabled                = local.is_production_environment
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}
module "parking_foi_pcn_gds_daily_summary_records" {
  source                         = "../modules/aws-glue-job"
  is_live_environment            = local.is_live_environment
  is_production_environment      = local.is_production_environment
  department                     = module.department_parking_data_source
  job_name                       = "${local.short_identifier_prefix}parking_foi_pcn_gds_daily_summary_records"
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  script_name                    = "parking_foi_pcn_gds_daily_summary_records"
  glue_version                   = "2.0"
  triggered_by_job               = module.parking_pcn_denormalisation.job_name
  job_description                = "Records of daily summarising data from the FOI Google Data Studio dashboard as need to be under 100,000"
  workflow_name                  = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  trigger_enabled                = local.is_production_environment
  glue_job_timeout               = 240
  number_of_workers_for_glue_job = 10
  glue_job_worker_type           = "G.1X"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--environment"         = var.environment
  }
}
