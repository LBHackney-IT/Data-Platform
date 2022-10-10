module "housing_repairs_elec_mech_fire_address_matching" {
  source                    = "../aws-glue-job"
  is_live_environment       = var.is_live_environment
  is_production_environment = var.is_production_environment

  department        = var.department
  job_name          = "${var.short_identifier_prefix}Housing Repairs - Electrical Mechnical Fire Safety ${title(replace(var.dataset_name, "-", " "))} Address Matching"
  helper_module_key = var.helper_module_key
  pydeequ_zip_key   = var.pydeequ_zip_key
  job_parameters = {
    "--addresses_api_data_database" = var.addresses_api_data_catalog
    "--addresses_api_data_table"    = "unrestricted_address_api_dbo_hackney_address"
    "--source_catalog_database"     = local.refined_zone_catalog_database_name
    "--source_catalog_table"        = "housing_repairs_elec_mech_fire_${replace(var.dataset_name, "-", "_")}_with_cleaned_addresses"
    "--target_destination"          = "s3://${var.trusted_zone_bucket_id}/housing-repairs/repairs/"
    "--match_to_property_shell"     = var.match_to_property_shell
  }
  glue_job_worker_type           = "G.1X"
  number_of_workers_for_glue_job = 6
  script_s3_object_key           = var.address_matching_script_key
  spark_ui_output_storage_id     = var.spark_ui_output_storage_id
  workflow_name                  = var.worksheet_resource.workflow_name
  triggered_by_crawler           = module.housing_repairs_elec_mech_fire_address_cleaning.crawler_name
}

