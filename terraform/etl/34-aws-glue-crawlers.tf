resource "aws_glue_catalog_database" "landing_zone_data_and_insight_address_matching" {
  count = local.is_live_environment ? 1 : 0

  name = "${local.identifier_prefix}-data-and-insight-address-matching-landing-zone"

  lifecycle {
    prevent_destroy = true
  }
}

// ==== RAW ZONE ===========
resource "aws_glue_catalog_database" "unrestricted_raw_zone" {
  name = "${local.identifier_prefix}-unrestricted_raw_zone"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_glue_catalog_database" "raw_zone_unrestricted_address_api" {
  name = "${local.identifier_prefix}-raw-zone-unrestricted-address-api"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_glue_crawler" "raw_zone_unrestricted_address_api_crawler" {
  tags = module.tags.values

  database_name = aws_glue_catalog_database.raw_zone_unrestricted_address_api.name
  name          = "${local.identifier_prefix}-raw-zone-unrestricted-address-api"
  role          = data.aws_iam_role.glue_role.arn
  table_prefix  = "unrestricted_address_api_"

  s3_target {
    path       = "s3://${module.raw_zone_data_source.bucket_id}/unrestricted/addresses_api/"
    exclusions = local.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 4
    }
  })
}

resource "aws_glue_trigger" "addresses_api_crawler_trigger" {
  tags = module.tags.values

  name     = "${local.short_identifier_prefix}Addresses API crawler Trigger"
  type     = "SCHEDULED"
  schedule = "cron(0 6 * * ? *)"
  enabled  = local.is_live_environment

  actions {
    crawler_name = aws_glue_crawler.raw_zone_unrestricted_address_api_crawler.name
  }
}

resource "aws_glue_crawler" "refined_zone_sandbox_crawler" {
  tags = module.tags.values

  database_name = module.department_sandbox_data_source.refined_zone_catalog_database_name
  name          = "${local.short_identifier_prefix}sandbox-refined-zone"
  role          = data.aws_iam_role.glue_role.arn

  s3_target {
    path       = "s3://${module.refined_zone_data_source.bucket_id}/sandbox/"
    exclusions = local.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 3
    }
  })
}
