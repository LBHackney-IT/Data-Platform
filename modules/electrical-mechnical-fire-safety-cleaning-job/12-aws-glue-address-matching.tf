resource "aws_glue_job" "housing_repairs_elec_mech_fire_address_matching_job" {

  tags = var.tags

  name              = "${var.short_identifier_prefix}Housing Repairs - Electrical Mechnical Fire Safety ${title(replace(var.dataset_name, "-", " "))} Address Matching"
  number_of_workers = 10
  worker_type       = "G.1X"
  role_arn          = var.glue_role_arn
  command {
    python_version  = "3"
    script_location = "s3://${var.glue_scripts_bucket_id}/${var.address_matching_script_key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--addresses_api_data_database" = var.addresses_api_data_catalog
    "--addresses_api_data_table"    = "unrestricted_address_api_dbo_hackney_address"
    "--source_catalog_database"     = var.refined_zone_catalog_database_name
    "--source_catalog_table"        = "housing_repairs_elec_mech_fire_${replace(var.dataset_name, "-", "_")}_with_cleaned_addresses"
    "--target_destination"          = "s3://${var.trusted_zone_bucket_id}/housing-repairs/repairs/"
    "--TempDir"                     = var.glue_temp_storage_bucket_id
    "--extra-py-files"              = "s3://${var.glue_scripts_bucket_id}/${var.helper_script_key}"
    "--match_to_property_shell"     = var.match_to_property_shell
  }
}

resource "aws_glue_trigger" "job_trigger" {
  tags = var.tags

  name          = "${var.identifier_prefix}-housing-repairs-elec-mech-fire-${var.dataset_name}-address-matching-job-trigger"
  type          = "CONDITIONAL"
  workflow_name = var.worksheet_resource.workflow_name


  predicate {
    conditions {
      crawler_name = module.housing_repairs_elec_mech_fire_address_cleaning.crawler_name
      crawl_state  = "SUCCEEDED"
    }
  }

  actions {
    job_name = aws_glue_job.housing_repairs_elec_mech_fire_address_matching_job.name
  }
}
