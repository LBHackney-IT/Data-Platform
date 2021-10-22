locals {
  glue_job_name = "${var.short_identifier_prefix}Housing Repairs - ${title(replace(var.dataset_name, "-", " "))} Cleaning"
}

module "housing_repairs_google_sheets_import" {
  source = "../aws-glue-job"

  department = var.department
  job_name   = local.glue_job_name
  job_parameters = {
    "--source_catalog_database"          = var.catalog_database
    "--source_catalog_table"             = var.source_catalog_table
    "--cleaned_repairs_s3_bucket_target" = "s3://${var.refined_zone_bucket_id}/housing-repairs/${var.dataset_name}/cleaned/"
    "--TempDir"                          = var.glue_temp_storage_bucket_id
    "--extra-py-files"                   = "s3://${var.glue_scripts_bucket_id}/${var.helper_script_key},s3://${var.glue_scripts_bucket_id}/${var.cleaning_helper_script_key}"
  }
  script_name            = var.address_cleaning_script_key
  workflow_name          = var.workflow_name
  triggered_by_crawler   = var.trigger_crawler_name
  glue_scripts_bucket_id = var.glue_scripts_bucket_id
  crawler_details = {
    database_name      = var.catalog_database
    s3_target_location = "s3://${var.refined_zone_bucket_id}/housing-repairs/${var.dataset_name}/cleaned/"
  }
}
