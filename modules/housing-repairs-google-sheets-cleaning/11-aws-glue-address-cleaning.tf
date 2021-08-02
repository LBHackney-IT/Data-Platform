resource "aws_glue_trigger" "housing_repairs_address_cleaning" {

  name          = "${var.identifier_prefix}-housing-repairs-${var.dataset_name}-address-cleaning-trigger"
  type          = "CONDITIONAL"
  workflow_name = var.workflow_name
  tags          = var.tags

  predicate {
    conditions {
      crawler_name = aws_glue_crawler.refined_zone_housing_repairs_cleaned_crawler.name
      crawl_state  = "SUCCEEDED"
    }
  }
  actions {
    arguments = {
      "--source_catalog_database" : var.refined_zone_catalog_database_name
      "--source_catalog_table" : "housing_repairs_${replace(var.dataset_name, "-", "_")}_cleaned"
      "--cleaned_addresses_s3_bucket_target" : "s3://${var.refined_zone_bucket_id}/housing-repairs/${var.dataset_name}/with-cleaned-addresses"
      "--source_address_column_header" : "property_address"
      "--source_postcode_column_header" : "None"
    }
    job_name = var.address_cleaning_job_name
  }
}