module "google_sheet_import_data_source" {
  source                    = "../aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department           = var.department
  job_name             = "Google Sheets Import Job - ${local.import_name}"
  script_s3_object_key = var.google_sheets_import_script_key
  crawler_details = {
    database_name      = var.glue_catalog_database_name
    s3_target_location = local.full_output_path
    table_prefix       = "${var.department.identifier_snake_case}_"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableGroupingPolicy = "CombineCompatibleSchemas"
      }
    })
  }
}

data "aws_glue_workflow" "workflow" {
  name = "${var.identifier_prefix}${local.import_name}"
}
