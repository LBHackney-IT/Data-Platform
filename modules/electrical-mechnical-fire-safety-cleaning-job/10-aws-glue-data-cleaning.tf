resource "aws_glue_job" "housing_repairs_elec_mech_fire_cleaning" {

  tags = var.tags

  name              = "${var.short_identifier_prefix}Housing Repairs - Electrical Mechnical Fire Safety ${title(replace(var.dataset_name, "-", " "))} Cleaning"
  number_of_workers = 10
  worker_type       = "G.1X"
  role_arn          = var.glue_role_arn
  command {
    python_version  = "3"
    script_location = "s3://${var.glue_scripts_bucket_id}/${var.script_key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--cleaned_repairs_s3_bucket_target" = "s3://${var.refined_zone_bucket_id}/housing-repairs/repairs-electrical-mechanical-fire/${var.dataset_name}/cleaned/"
    "--source_catalog_database"          = var.catalog_database
    "--source_catalog_table"             = var.worksheet_resource.catalog_table
    "--TempDir"                          = var.glue_temp_storage_bucket_id
    "--extra-py-files"                   = "s3://${var.glue_scripts_bucket_id}/${var.helper_script_key},s3://${var.glue_scripts_bucket_id}/${var.cleaning_helper_script_key}"
  }
}

resource "aws_glue_trigger" "housing_repairs_elec_mech_fire_cleaning_job" {
  tags = var.tags

  name          = "${var.identifier_prefix}-housing-repairs-elec-mech-fire-${var.dataset_name}-cleaning-job-trigger"
  type          = "CONDITIONAL"
  workflow_name = var.worksheet_resource.workflow_name

  predicate {
    conditions {
      crawler_name = var.worksheet_resource.crawler_name
      crawl_state  = "SUCCEEDED"
    }
  }

  actions {
    job_name = aws_glue_job.housing_repairs_elec_mech_fire_cleaning.name
  }
}
