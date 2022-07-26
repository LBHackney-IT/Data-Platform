# Import test data
module "spreadsheet_import_data_source" {
  source                    = "../aws-glue-job"
  is_live_environment       = var.is_live_environment
  is_production_environment = var.is_production_environment

  department           = var.department
  job_name             = "Spreadsheet Import Job - ${var.department.identifier}-${var.glue_job_name}"
  script_s3_object_key = var.spreadsheet_import_script_key
  crawler_details = {
    database_name      = var.glue_catalog_database_name
    s3_target_location = "s3://${var.raw_zone_bucket_id}/${var.department.identifier}/${var.output_folder_name}"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableLevelConfiguration = 3
      }
    })
  }
}

data "aws_glue_workflow" "workflow" {
  name = "${var.identifier_prefix}${local.import_name}-${var.output_folder_name}"
}
