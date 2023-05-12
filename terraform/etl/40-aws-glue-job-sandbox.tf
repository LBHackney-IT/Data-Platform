module "load_locations_vaccine_to_refined_sandbox" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department                 = module.department_sandbox_data_source
  job_name                   = "${local.short_identifier_prefix}daro_covid_locations_and_vaccinations"
  script_name                = "daro_covid_locations_and_vaccinations"
  pydeequ_zip_key            = data.aws_s3_object.pydeequ.key
  helper_module_key          = data.aws_s3_object.helpers.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  job_parameters = {
    "--cleaned_covid_locations_s3_bucket_target" = "${module.refined_zone_data_source.bucket_id}/sandbox/daro-covid-locations-vaccinations-cleaned"
    "--source_catalog_database"                  = module.department_sandbox_data_source.raw_zone_catalog_database_name
    "--source_catalog_table"                     = "sandbox_daro_covid_locations"
    "--source_catalog_table2"                    = "sandbox_daro_covid_vaccinations"
  }
  crawler_details = {
    database_name      = module.department_sandbox_data_source.refined_zone_catalog_database_name
    s3_target_location = "s3://${module.refined_zone_data_source.bucket_id}/sandbox/daro-covid-locations-vaccinations-cleaned"
  }
}

module "job_template" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department                 = module.department_sandbox_data_source
  job_name                   = "${local.short_identifier_prefix}job_template"
  script_name                = "job_script_template"
  pydeequ_zip_key            = data.aws_s3_object.pydeequ.key
  helper_module_key          = data.aws_s3_object.helpers.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  job_parameters = {
    "--s3_bucket_target"        = "s3://${module.refined_zone_data_source.bucket_id}/sandbox/some-target-location-in-the-refined-zone"
    "--source_catalog_database" = module.department_sandbox_data_source.raw_zone_catalog_database_name
    "--source_catalog_table"    = "some_table_name"
  }
}

module "load_covid_data_to_refined_marta" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department                 = module.department_sandbox_data_source
  job_name                   = "${local.short_identifier_prefix}marta_training_job"
  script_name                = "marta_training_job"
  pydeequ_zip_key            = data.aws_s3_object.pydeequ.key
  helper_module_key          = data.aws_s3_object.helpers.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  job_parameters = {
    "--cleaned_covid_locations_s3_bucket_target" = "${module.refined_zone_data_source.bucket_id}/sandbox/marta-covid-locations-vaccinations-cleaned"
    "--source_catalog_database"                  = module.department_sandbox_data_source.raw_zone_catalog_database_name
    "--source_catalog_table"                     = "sandbox_daro_covid_locations"
    "--source_catalog_table2"                    = "sandbox_daro_covid_vaccinations"
  }
  crawler_details = {
    database_name      = module.department_sandbox_data_source.refined_zone_catalog_database_name
    s3_target_location = "s3://${module.refined_zone_data_source.bucket_id}/sandbox/marta-covid-locations-vaccinations-cleaned"
  }
}


module "load_covid_data_to_refined_adam" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department                 = module.department_sandbox_data_source
  job_name                   = "${local.short_identifier_prefix}load_covid_data_to_refined_adam"
  script_name                = "adam_covid"
  pydeequ_zip_key            = data.aws_s3_object.pydeequ.key
  helper_module_key          = data.aws_s3_object.helpers.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  job_parameters = {
    "--s3_bucket_target"        = "s3://${module.refined_zone_data_source.bucket_id}/sandbox/covid_adam"
    "--source_catalog_database" = module.department_sandbox_data_source.raw_zone_catalog_database_name
    "--source_catalog_table"    = "sandbox_covid_vaccinations_adam"
    "--source_catalog_table2"   = "sandbox_covid_locations_adam"
  }
  crawler_details = {
    database_name      = module.department_sandbox_data_source.refined_zone_catalog_database_name
    s3_target_location = "s3://${module.refined_zone_data_source.bucket_id}/sandbox/covid_adam"
  }
}



module "job_template_tim" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department                 = module.department_sandbox_data_source
  job_name                   = "${local.short_identifier_prefix}training_job_tim"
  script_name                = "training_job_tim"
  pydeequ_zip_key            = data.aws_s3_object.pydeequ.key
  helper_module_key          = data.aws_s3_object.helpers.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  job_parameters = {
    "--s3_bucket_target"          = "s3://${module.refined_zone_data_source.bucket_id}/sandbox/tim-covid-vaccinations"
    "--source_catalog_database"   = module.department_sandbox_data_source.raw_zone_catalog_database_name
    "--source_locations_table"    = "sandbox_tim_covid_vaccination_locations"
    "--source_vaccinations_table" = "sandbox_tim_covid_vaccination_vaccinations"
  }
}

module "steve_covid_locations_and_vaccinations_sandbox" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department                 = module.department_sandbox_data_source
  job_name                   = "${local.short_identifier_prefix}steve_covid_locations_and_vaccinations"
  script_name                = "steve_covid_locations_and_vaccinations"
  helper_module_key          = data.aws_s3_object.helpers.key
  pydeequ_zip_key            = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  job_parameters = {
    "--s3_bucket_target"          = "s3://${module.refined_zone_data_source.bucket_id}/sandbox/steve-covid-vaccinations-locations"
    "--source_catalog_database"   = "sandbox-raw-zone"
    "--source_locations_table"    = "sandbox_daro_covid_locations"
    "--source_vaccinations_table" = "sandbox_daro_covid_vaccinations"
  }
  crawler_details = {
    database_name      = module.department_sandbox_data_source.refined_zone_catalog_database_name
    s3_target_location = "s3://${module.refined_zone_data_source.bucket_id}/sandbox/steve-covid-vaccinations-locations"
    table_prefix       = "sandbox_"
  }
}

module "stg_job_template_huu_do_sandbox" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department                 = module.department_sandbox_data_source
  job_name                   = "${local.short_identifier_prefix}job_template_huu_do"
  script_name                = "stg_job_template_huu_do"
  pydeequ_zip_key            = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  helper_module_key          = data.aws_s3_object.helpers.key
  job_parameters = {
    "--s3_bucket_target"         = "s3://${module.refined_zone_data_source.bucket_id}/sandbox/covid-data-huu-do/"
    "--source_catalog_database"  = module.department_sandbox_data_source.raw_zone_catalog_database_name
    "--source_catalog_database2" = module.department_sandbox_data_source.raw_zone_catalog_database_name
    "--source_catalog_table"     = "sandbox_covid_locations_adam"
    "--source_catalog_table2"    = "sandbox_covid_vaccinations_adam"
  }
  crawler_details = {
    database_name      = module.department_sandbox_data_source.refined_zone_catalog_database_name
    s3_target_location = "s3://${module.refined_zone_data_source.bucket_id}/sandbox/covid-data-huu-do/"
  }
}

module "covid_vaccinations_verlander_sandbox" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department                 = module.department_sandbox_data_source
  job_name                   = "${local.short_identifier_prefix}covid_vaccinations_verlander"
  script_name                = "covid_vaccinations_verlander"
  pydeequ_zip_key            = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  helper_module_key          = data.aws_s3_object.helpers.key
  job_parameters = {
    "--s3_bucket_target"                  = "s3://${module.refined_zone_data_source.bucket_id}/sandbox/covid_locations_verlander/"
    "--source_catalog_database"           = module.department_sandbox_data_source.raw_zone_catalog_database_name
    "--source_catalog_table"              = "sandbox_everlander_covid_locations"
    "--source_catalog_table_vaccinations" = "sandbox_everlander_covid_vaccinations"
  }
  crawler_details = {
    database_name      = module.department_sandbox_data_source.refined_zone_catalog_database_name
    s3_target_location = "s3://${module.refined_zone_data_source.bucket_id}/sandbox/covid_locations_verlander/"
  }
}

module "covid_vaccinations_arda_sandbox" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department                 = module.department_sandbox_data_source
  job_name                   = "${local.short_identifier_prefix}covid_vaccinations_arda"
  script_name                = "covid_vaccinations_arda"
  pydeequ_zip_key            = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  helper_module_key          = data.aws_s3_object.helpers.key
  job_parameters = {
    "--s3_bucket_target"                  = "s3://${module.refined_zone_data_source.bucket_id}/sandbox/covid_locations_arda/"
    "--source_catalog_database"           = module.department_sandbox_data_source.raw_zone_catalog_database_name
    "--source_catalog_table"              = "sandbox_arda_covid_vaccination_loc"
    "--source_catalog_table_vaccinations" = "sandbox_arda_covid_vaccination_vac"
  }
  crawler_details = {
    database_name      = module.department_sandbox_data_source.refined_zone_catalog_database_name
    s3_target_location = "s3://${module.refined_zone_data_source.bucket_id}/sandbox/covid_locations_arda/"
  }
}
#
