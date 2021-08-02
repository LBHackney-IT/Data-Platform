resource "aws_glue_job" "housing_repairs_data_cleaning" {
  tags = var.tags

  name              = "${var.short_identifier_prefix}Housing Repairs - ${title(replace(var.dataset_name, "-", " "))} Cleaning"
  number_of_workers = 10
  worker_type       = "G.1X"
  role_arn          = var.glue_role_arn
  command {
    python_version  = "3"
    script_location = "s3://${var.glue_scripts_bucket_id}/${var.data_cleaning_script_key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--cleaned_repairs_s3_bucket_target" = "s3://${var.refined_zone_bucket_id}/housing-repairs/${var.dataset_name}/cleaned/"
    "--source_catalog_database"          = var.catalog_database
    "--source_catalog_table"             = var.source_catalog_table
    "--TempDir"                          = var.glue_temp_storage_bucket_id
    "--extra-py-files"                   = "s3://${var.glue_scripts_bucket_id}/${var.helper_script_key},s3://${var.glue_scripts_bucket_id}/${var.cleaning_helper_script_key}"
  }
}

resource "aws_glue_trigger" "housing_repairs_cleaning_job" {
  tags = var.tags

  name          = "${var.identifier_prefix}-housing-repairs-${var.dataset_name}-cleaning-job-trigger"
  type          = "CONDITIONAL"
  workflow_name = var.workflow_name

  predicate {
    conditions {
      crawler_name = var.trigger_crawler_name
      crawl_state  = "SUCCEEDED"
    }
  }

  actions {
    job_name = aws_glue_job.housing_repairs_data_cleaning.name
  }
}

resource "aws_glue_crawler" "refined_zone_housing_repairs_cleaned_crawler" {
  tags = var.tags

  database_name = var.refined_zone_catalog_database_name
  name          = "${var.short_identifier_prefix}refined-zone-housing-repairs-${var.dataset_name}-cleaned"
  role          = var.glue_role_arn
  table_prefix  = "housing_repairs_${replace(var.dataset_name, "-", "_")}_"

  s3_target {
    path       = "s3://${var.refined_zone_bucket_id}/housing-repairs/${var.dataset_name}/cleaned/"
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

resource "aws_glue_trigger" "housing_repairs_cleaned_crawler" {
  tags = var.tags

  name          = "${var.identifier_prefix}-housing-repairs-${var.dataset_name}-cleaning-crawler-trigger"
  type          = "CONDITIONAL"
  workflow_name = var.workflow_name

  predicate {
    conditions {
      job_name = aws_glue_job.housing_repairs_data_cleaning.name
      state    = "SUCCEEDED"
    }
  }
  actions {
    crawler_name = aws_glue_crawler.refined_zone_housing_repairs_cleaned_crawler.name
  }
}
