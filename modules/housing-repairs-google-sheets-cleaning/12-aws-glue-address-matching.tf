resource "aws_glue_job" "housing_repairs_levenshtein_address_matching" {
  tags = var.tags

  name              = "Housing Repairs - ${title(replace(var.dataset_name, "-", " "))} Address Matching"
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
    "--source_catalog_table"        = "housing_repairs_${replace(var.dataset_name, "-", "_")}_with_cleaned_addresses"
    "--target_destination"          = "s3://${var.trusted_zone_bucket_id}/housing-repairs/repairs/"
    "--TempDir"                     = var.glue_temp_storage_bucket_id
    "--extra-py-files"              = "s3://${var.glue_scripts_bucket_id}/${var.helper_script_key}"
  }
}
#
resource "aws_glue_trigger" "housing_repairs_levenshtein_address_matching" {

  name          = "${var.short_identifier_prefix}housing-repairs-${var.dataset_name}-address-matching-trigger"
  type          = "CONDITIONAL"
  workflow_name = var.workflow_name
  tags          = var.tags

  predicate {
    conditions {
      crawler_name = aws_glue_crawler.refined_zone_housing_repairs_with_cleaned_addresses_crawler.name
      crawl_state  = "SUCCEEDED"
    }
  }
  actions {
    job_name = aws_glue_job.housing_repairs_levenshtein_address_matching.name
  }
}
