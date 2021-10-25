module "housing_repairs_google_sheets_cleaning" {
  source = "../aws-glue-job"

  department = var.department
  job_name   = "${local.glue_job_name} Cleaning"
  job_parameters = {
    "--source_catalog_database"          = var.catalog_database
    "--source_catalog_table"             = var.source_catalog_table
    "--cleaned_repairs_s3_bucket_target" = "s3://${var.refined_zone_bucket_id}/housing-repairs/${var.dataset_name}/cleaned/"
    "--TempDir"                          = var.glue_temp_storage_bucket_id
    "--extra-py-files"                   = local.extra_py_files
  }
  script_name            = var.data_cleaning_script_key
  workflow_name          = var.workflow_name
  triggered_by_crawler   = var.trigger_crawler_name
  glue_scripts_bucket_id = var.glue_scripts_bucket_id
  crawler_details = {
    database_name      = var.catalog_database
    s3_target_location = "s3://${var.refined_zone_bucket_id}/housing-repairs/${var.dataset_name}/cleaned/"
  }
}
