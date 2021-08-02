resource "aws_glue_crawler" "refined_zone_housing_repairs_elec_mech_fire_cleaned_crawler" {
  tags = var.tags

  database_name = var.refined_zone_catalog_database_name
  name          = "${var.short_identifier_prefix}refined-zone-housing-repairs-elec-mech-fire-${var.dataset_name}-cleaned"
  role          = var.glue_role_arn
  table_prefix  = "housing_repairs_elec_mech_fire_${replace(var.dataset_name, "-", "_")}_"

  s3_target {
    path = "s3://${var.refined_zone_bucket_id}/housing-repairs/repairs-electrical-mechanical-fire/${var.dataset_name}/"


    exclusions = var.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
    }
  })
}

// Trigger the crawler after all jobs have run
resource "aws_glue_trigger" "housing_repairs_elec_mech_fire_crawler" {
  tags = var.tags

  name          = "${var.identifier_prefix}-housing-repairs-elec-mech-fire-${var.dataset_name}-address-matching-crawler-trigger"
  type          = "CONDITIONAL"
  workflow_name = var.worksheet_resource.workflow_name

  predicate {
    conditions {
      job_name = aws_glue_job.housing_repairs_elec_mech_fire_address_matching.name
      state    = "SUCCEEDED"
    }
  }
  actions {
    crawler_name = aws_glue_crawler.refined_zone_housing_repairs_elec_mech_fire_cleaned_crawler.name
  }
}
