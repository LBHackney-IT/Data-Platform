locals {
  s3_object_tags = { for k, v in var.department.tags : k => v if k != "PlatformDepartment" }
  object_key     = "scripts/${var.department.identifier}/${var.data_cleaning_script_name}.py"
}

resource "aws_s3_bucket_object" "housing_repairs_repairs_cleaning_script" {
  tags = local.s3_object_tags

  bucket = var.glue_scripts_bucket_id
  key    = local.object_key
  acl    = "private"
  source = "../${local.object_key}"
  etag   = filemd5("../${local.object_key}")
}

module "housing_repairs_google_sheets_cleaning" {
  source = "../aws-glue-job"

  department = var.department
  job_name   = "${local.glue_job_name} Cleaning"
  job_parameters = {
    "--source_catalog_database"          = var.catalog_database
    "--source_catalog_table"             = var.source_catalog_table
    "--cleaned_repairs_s3_bucket_target" = "s3://${var.refined_zone_bucket_id}/housing-repairs/${var.dataset_name}/cleaned/"
    "--TempDir"                          = "${var.glue_temp_storage_bucket_url}/${var.department.identifier}/"
    "--extra-py-files"                   = "s3://${var.glue_scripts_bucket_id}/${var.helper_script_key},s3://${var.glue_scripts_bucket_id}/${var.cleaning_helper_script_key}"
  }
  script_name            = aws_s3_bucket_object.housing_repairs_repairs_cleaning_script.key
  workflow_name          = var.workflow_name
  triggered_by_crawler   = var.trigger_crawler_name
  glue_scripts_bucket_id = var.glue_scripts_bucket_id
  crawler_details = {
    table_prefix       = "housing_repairs_${replace(var.dataset_name, "-", "_")}_"
    database_name      = var.catalog_database
    s3_target_location = "s3://${var.refined_zone_bucket_id}/housing-repairs/${var.dataset_name}/cleaned/"
  }
}
