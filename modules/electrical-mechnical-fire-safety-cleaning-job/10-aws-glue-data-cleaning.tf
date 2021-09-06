module "housing_repairs_elec_mech_fire_cleaning" {
  source              = "../aws-glue-job-with-crawler"
  tags                = var.tags
  workflow_name       = var.worksheet_resource.workflow_name
  crawler_to_trigger  = var.worksheet_resource.crawler_name
  job_name            = "${var.short_identifier_prefix}Housing Repairs - Electrical Mechnical Fire Safety ${title(replace(var.dataset_name, "-", " "))} Cleaning"
  glue_role_arn       = var.glue_role_arn
  job_script_location = "s3://${var.glue_scripts_bucket_id}/${var.script_key}"
  job_arguments = {
    "--cleaned_repairs_s3_bucket_target" = "s3://${var.refined_zone_bucket_id}/housing-repairs/repairs-electrical-mechanical-fire/${var.dataset_name}/cleaned/"
    "--source_catalog_database"          = var.catalog_database
    "--source_catalog_table"             = var.worksheet_resource.catalog_table
    "--TempDir"                          = var.glue_temp_storage_bucket_id
    "--extra-py-files"                   = "s3://${var.glue_scripts_bucket_id}/${var.helper_script_key},s3://${var.glue_scripts_bucket_id}/${var.cleaning_helper_script_key},s3://${var.glue_scripts_bucket_id}/${var.pydeequ_zip_key}"
    "--extra-jars"                       = var.deequ_jar_file_path
  }
  name_prefix        = "${var.identifier_prefix}-housing-repairs-elec-mech-fire-${var.dataset_name}-cleaning"
  database_name      = var.refined_zone_catalog_database_name
  table_prefix       = "housing_repairs_elec_mech_fire_${replace(var.dataset_name, "-", "_")}_"
  s3_target_location = "s3://${var.refined_zone_bucket_id}/housing-repairs/repairs-electrical-mechanical-fire/${var.dataset_name}/cleaned/"
}
