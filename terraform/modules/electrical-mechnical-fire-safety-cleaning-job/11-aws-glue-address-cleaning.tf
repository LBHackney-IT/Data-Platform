module "housing_repairs_elec_mech_fire_address_cleaning" {
  source                    = "../aws-glue-job"
  is_live_environment       = var.is_live_environment
  is_production_environment = var.is_production_environment

  department        = var.department
  job_name          = "${var.short_identifier_prefix}Housing Repairs - Electrical Mechnical Fire Safety ${title(replace(var.dataset_name, "-", " "))} Address Cleaning"
  glue_version      = var.is_production_environment ? "2.0" : "4.0"
  helper_module_key = var.helper_module_key
  pydeequ_zip_key   = var.pydeequ_zip_key
  job_parameters = {
    "--source_catalog_database"            = local.refined_zone_catalog_database_name
    "--source_catalog_table"               = local.source_catalog_table
    "--cleaned_addresses_s3_bucket_target" = local.cleaned_addresses_s3_bucket_target
    "--source_address_column_header"       = "property_address"
    "--source_postcode_column_header"      = "None"
  }
  workflow_name              = var.worksheet_resource.workflow_name
  script_s3_object_key       = var.address_cleaning_script_key
  spark_ui_output_storage_id = var.spark_ui_output_storage_id
  triggered_by_crawler       = module.housing_repairs_elec_mech_fire_cleaning.crawler_name
  crawler_details = {
    database_name      = local.refined_zone_catalog_database_name
    s3_target_location = "s3://${var.refined_zone_bucket_id}/housing-repairs/repairs-electrical-mechanical-fire/${var.dataset_name}/with-cleaned-addresses/"
    table_prefix       = "housing_repairs_elec_mech_fire_${replace(var.dataset_name, "-", "_")}_"
    configuration      = null
  }
}

locals {
  source_catalog_table               = "housing_repairs_elec_mech_fire_${replace(var.dataset_name, "-", "_")}_cleaned"
  cleaned_addresses_s3_bucket_target = "s3://${var.refined_zone_bucket_id}/housing-repairs/repairs-electrical-mechanical-fire/${var.dataset_name}/with-cleaned-addresses"
}
