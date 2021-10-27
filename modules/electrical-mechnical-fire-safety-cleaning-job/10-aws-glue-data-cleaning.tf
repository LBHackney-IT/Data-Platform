module "housing_repairs_elec_mech_fire_cleaning" {
  source = "../aws-glue-job"

  department             = var.department
  job_name               = "${var.short_identifier_prefix}Housing Repairs - Electrical Mechnical Fire Safety ${title(replace(var.dataset_name, "-", " "))} Cleaning"
  glue_scripts_bucket_id = var.glue_scripts_bucket_id
  job_parameters = {
    "--cleaned_repairs_s3_bucket_target" = "s3://${var.refined_zone_bucket_id}/housing-repairs/repairs-electrical-mechanical-fire/${var.dataset_name}/cleaned/"
    "--source_catalog_database"          = local.catalog_database
    "--source_catalog_table"             = var.worksheet_resource.catalog_table
    "--deequ_metrics_location"           = "s3://${var.refined_zone_bucket_id}/quality-metrics/department=${var.department.identifier}/dataset=${var.dataset_name}-cleaned/deequ-metrics.json"
    "--TempDir"                          = "${var.glue_temp_storage_bucket_id}/${var.department.identifier}/"
    "--extra-py-files"                   = "s3://${var.glue_scripts_bucket_id}/${var.helper_script_key},s3://${var.glue_scripts_bucket_id}/${var.cleaning_helper_script_key},s3://${var.glue_scripts_bucket_id}/${var.pydeequ_zip_key}"
    "--extra-jars"                       = var.deequ_jar_file_path
  }
  workflow_name        = var.worksheet_resource.workflow_name
  script_name          = var.script_key
  triggered_by_crawler = var.worksheet_resource.crawler_name
  crawler_details = {
    database_name      = local.refined_zone_catalog_database_name
    s3_target_location = "s3://${var.refined_zone_bucket_id}/housing-repairs/repairs-electrical-mechanical-fire/${var.dataset_name}/cleaned/"
    table_prefix       = "housing_repairs_elec_mech_fire_${replace(var.dataset_name, "-", "_")}_"
  }
}
