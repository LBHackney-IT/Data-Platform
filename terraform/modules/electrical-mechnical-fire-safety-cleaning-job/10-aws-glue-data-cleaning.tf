locals {
  s3_object_tags = { for k, v in var.department.tags : k => v if k != "PlatformDepartment" }
  object_key     = "${var.department.identifier_snake_case}/${var.script_name}.py"
}

resource "aws_s3_bucket_object" "housing_repairs_elec_mech_fire_data_cleaning_script" {
  bucket      = var.glue_scripts_bucket_id
  key         = "scripts/${local.object_key}"
  acl         = "private"
  source      = "../../scripts/jobs/${local.object_key}"
  source_hash = filemd5("../../scripts/jobs/${local.object_key}")
}

module "housing_repairs_elec_mech_fire_cleaning" {
  source                    = "../aws-glue-job"
  is_live_environment       = var.is_live_environment
  is_production_environment = var.is_production_environment

  department        = var.department
  job_name          = "${var.short_identifier_prefix}Housing Repairs - Electrical Mechnical Fire Safety ${title(replace(var.dataset_name, "-", " "))} Cleaning"
  helper_module_key = var.helper_module_key
  pydeequ_zip_key   = var.pydeequ_zip_key
  job_parameters = {
    "--cleaned_repairs_s3_bucket_target" = "s3://${var.refined_zone_bucket_id}/housing-repairs/repairs-electrical-mechanical-fire/${var.dataset_name}/cleaned/"
    "--source_catalog_database"          = local.raw_zone_catalog_database_name
    "--source_catalog_table"             = var.worksheet_resource.catalog_table
    "--deequ_metrics_location"           = "s3://${var.refined_zone_bucket_id}/quality-metrics/department=${var.department.identifier}/dataset=${var.dataset_name}-cleaned/deequ-metrics.json"
    "--extra-jars"                       = var.deequ_jar_file_path
  }
  workflow_name              = var.worksheet_resource.workflow_name
  script_s3_object_key       = aws_s3_bucket_object.housing_repairs_elec_mech_fire_data_cleaning_script.key
  triggered_by_crawler       = var.worksheet_resource.crawler_name
  spark_ui_output_storage_id = var.spark_ui_output_storage_id
  crawler_details = {
    database_name      = local.refined_zone_catalog_database_name
    s3_target_location = "s3://${var.refined_zone_bucket_id}/housing-repairs/repairs-electrical-mechanical-fire/${var.dataset_name}/cleaned/"
    table_prefix       = "housing_repairs_elec_mech_fire_${replace(var.dataset_name, "-", "_")}_"
    configuration      = null
  }
}
