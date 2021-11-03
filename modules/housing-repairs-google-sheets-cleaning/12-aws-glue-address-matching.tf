module "housing_repairs_google_sheets_address_matching" {
  source = "../aws-glue-job"

  department = var.department
  job_name   = "${local.glue_job_name} Address Matching"
  job_parameters = {
    "--addresses_api_data_database" = var.addresses_api_data_catalog
    "--addresses_api_data_table"    = "unrestricted_address_api_dbo_hackney_address"
    "--source_catalog_database"     = var.refined_zone_catalog_database_name
    "--source_catalog_table"        = "housing_repairs_${replace(var.dataset_name, "-", "_")}_with_cleaned_addresses"
    "--target_destination"          = "s3://${var.trusted_zone_bucket_id}/housing-repairs/repairs/"
    "--TempDir"                     = "${var.glue_temp_storage_bucket_url}/${var.department.identifier}/"
    "--extra-py-files"              = "s3://${var.glue_scripts_bucket_id}/${var.helper_script_key}"
    "--match_to_property_shell"     = var.match_to_property_shell
  }
  glue_job_worker_type           = "G.1X"
  number_of_workers_for_glue_job = 6
  script_name                    = var.address_matching_script_key
  workflow_name                  = var.workflow_name
  triggered_by_crawler           = module.housing_repairs_google_sheets_address_cleaning.crawler_name
  glue_scripts_bucket_id         = var.glue_scripts_bucket_id
}
