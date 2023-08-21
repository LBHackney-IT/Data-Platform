module "housing_repairs_google_sheets_address_cleaning" {
  source                    = "../aws-glue-job"
  is_live_environment       = var.is_live_environment
  is_production_environment = var.is_production_environment

  department        = var.department
  job_name          = "${local.glue_job_name} Address Cleaning"
  glue_version      = var.is_production_environment ? "2.0" : "4.0"
  helper_module_key = var.helper_module_key
  pydeequ_zip_key   = var.pydeequ_zip_key
  job_parameters = {
    "--source_catalog_database"            = local.refined_zone_catalog_database_name
    "--source_catalog_table"               = "housing_repairs_${replace(var.dataset_name, "-", "_")}_cleaned"
    "--cleaned_addresses_s3_bucket_target" = "s3://${var.refined_zone_bucket_id}/housing-repairs/${var.dataset_name}/with-cleaned-addresses"
    "--source_address_column_header"       = "property_address"
    "--source_postcode_column_header"      = "None"
  }
  script_s3_object_key       = var.address_cleaning_script_key
  spark_ui_output_storage_id = var.spark_ui_output_storage_id
  workflow_name              = var.workflow_name
  triggered_by_crawler       = module.housing_repairs_google_sheets_cleaning.crawler_name
  crawler_details = {
    table_prefix       = "housing_repairs_${replace(var.dataset_name, "-", "_")}_"
    database_name      = local.refined_zone_catalog_database_name
    s3_target_location = "s3://${var.refined_zone_bucket_id}/housing-repairs/${var.dataset_name}/with-cleaned-addresses/"
    configuration      = null
  }
}
