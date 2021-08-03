module "housing_repairs_elec_mech_fire_address_cleaning" {
  source              = "../aws-glue-job-with-crawler"
  tags                = var.tags
  workflow_name       = var.worksheet_resource.workflow_name
  crawler_to_trigger  = module.housing_repairs_elec_mech_fire_cleaning.crawler_name
  job_name            = "${var.short_identifier_prefix}Housing Repairs - Electrical Mechnical Fire Safety ${title(replace(var.dataset_name, "-", " "))} Address Cleaning"
  glue_role_arn       = var.glue_role_arn
  job_script_location = "s3://${var.glue_scripts_bucket_id}/${var.address_cleaning_script_key}"
  job_arguments = {
    "--TempDir"        = var.glue_temp_storage_bucket_id
    "--extra-py-files" = "s3://${var.glue_scripts_bucket_id}/${var.helper_script_key}"
    "--source_catalog_database" : var.refined_zone_catalog_database_name
    "--source_catalog_table" : local.source_catalog_table
    "--cleaned_addresses_s3_bucket_target" : local.cleaned_addresses_s3_bucket_target
    "--source_address_column_header" : "property_address"
    "--source_postcode_column_header" : "None"
  }
  name_prefix        = "${var.identifier_prefix}-housing-repairs-elec-mech-fire-${var.dataset_name}-address-cleaning"
  database_name      = var.refined_zone_catalog_database_name
  table_prefix       = "housing_repairs_elec_mech_fire_${replace(var.dataset_name, "-", "_")}_"
  s3_target_location = "s3://${var.refined_zone_bucket_id}/housing-repairs/repairs-electrical-mechanical-fire/${var.dataset_name}/with-cleaned-addresses/"
}

locals {
  source_catalog_table               = "housing_repairs_elec_mech_fire_${replace(var.dataset_name, "-", "_")}_cleaned"
  cleaned_addresses_s3_bucket_target = "s3://${var.refined_zone_bucket_id}/housing-repairs/repairs-electrical-mechanical-fire/${var.dataset_name}/with-cleaned-addresses"
}
