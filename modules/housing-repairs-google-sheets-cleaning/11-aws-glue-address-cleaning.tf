resource "aws_glue_job" "address_cleaning" {
  tags = var.tags

  name              = "${var.short_identifier_prefix}Housing Repairs - ${title(replace(var.dataset_name, "-", " "))} Address Cleaning"
  number_of_workers = 10
  worker_type       = "G.1X"
  role_arn          = var.glue_role_arn
  command {
    python_version  = "3"
    script_location = "s3://${var.glue_scripts_bucket_id}/${var.address_cleaning_script_key}"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  glue_version = "2.0"

  default_arguments = {
    "--TempDir"                            = var.glue_temp_storage_bucket_id
    "--extra-py-files"                     = "s3://${var.glue_scripts_bucket_id}/${var.helper_script_key},s3://${var.glue_scripts_bucket_id}/${var.cleaning_helper_script_key}"
    "--source_catalog_database"            = var.refined_zone_catalog_database_name
    "--source_catalog_table"               = "housing_repairs_${replace(var.dataset_name, "-", "_")}_cleaned"
    "--cleaned_addresses_s3_bucket_target" = "s3://${var.refined_zone_bucket_id}/housing-repairs/${var.dataset_name}/with-cleaned-addresses"
    "--source_address_column_header"       = "property_address"
    "--source_postcode_column_header"      = "None"
  }
}

resource "aws_glue_trigger" "housing_repairs_address_cleaning" {

  name          = "${var.short_identifier_prefix}-housing-repairs-${var.dataset_name}-address-cleaning-trigger"
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
    job_name = aws_glue_job.address_cleaning.name
  }
}

resource "aws_glue_trigger" "housing_repairs_cleaned_crawler_trigger" {

  name          = "${var.short_identifier_prefix}-housing-repairs-${var.dataset_name}-address-cleaned-crawler-trigger"
  type          = "CONDITIONAL"
  workflow_name = var.workflow_name
  tags          = var.tags

  predicate {
    conditions {
      job_name = aws_glue_job.address_cleaning.name
      state    = "SUCCEEDED"
    }
  }
  actions {
    crawler_name = aws_glue_crawler.refined_zone_housing_repairs_with_cleaned_addresses_crawler.name
  }
}

resource "aws_glue_crawler" "refined_zone_housing_repairs_with_cleaned_addresses_crawler" {
  tags = var.tags

  database_name = var.refined_zone_catalog_database_name
  name          = "${var.short_identifier_prefix}refined-zone-housing-repairs-${var.dataset_name}-with-cleaned-addresses"
  role          = var.glue_role_arn
  table_prefix  = "housing_repairs_${replace(var.dataset_name, "-", "_")}_"

  s3_target {
    path       = "s3://${var.refined_zone_bucket_id}/housing-repairs/${var.dataset_name}/with-cleaned-addresses/"
    exclusions = var.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
    }
    Grouping = {
      TableLevelConfiguration = 4
    }
  })
}
