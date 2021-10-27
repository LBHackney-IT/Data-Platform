module "housing_repairs_elec_mech_fire_address_cleaning" {
  source = "../aws-glue-job"

  department             = var.department
  job_name               = "${var.short_identifier_prefix}Housing Repairs - Electrical Mechnical Fire Safety ${title(replace(var.dataset_name, "-", " "))} Address Cleaning"
  glue_scripts_bucket_id = var.glue_scripts_bucket_id
  job_parameters = {
    "--TempDir"                            = "${var.glue_temp_storage_bucket_id}/${var.department.identifier}/"
    "--extra-py-files"                     = "s3://${var.glue_scripts_bucket_id}/${var.helper_script_key}"
    "--source_catalog_database"            = local.refined_zone_catalog_database_name
    "--source_catalog_table"               = local.source_catalog_table
    "--cleaned_addresses_s3_bucket_target" = local.cleaned_addresses_s3_bucket_target
    "--source_address_column_header"       = "property_address"
    "--source_postcode_column_header"      = "None"
  }
  workflow_name        = var.worksheet_resource.workflow_name
  script_name          = var.address_cleaning_script_key
  triggered_by_crawler = module.housing_repairs_elec_mech_fire_cleaning.crawler_name
  crawler_details = {
    database_name      = local.refined_zone_catalog_database_name
    s3_target_location = "s3://${var.refined_zone_bucket_id}/housing-repairs/repairs-electrical-mechanical-fire/${var.dataset_name}/with-cleaned-addresses/"
    table_prefix       = "housing_repairs_elec_mech_fire_${replace(var.dataset_name, "-", "_")}_"
  }
}

locals {
  source_catalog_table               = "housing_repairs_elec_mech_fire_${replace(var.dataset_name, "-", "_")}_cleaned"
  cleaned_addresses_s3_bucket_target = "s3://${var.refined_zone_bucket_id}/housing-repairs/repairs-electrical-mechanical-fire/${var.dataset_name}/with-cleaned-addresses"
}
