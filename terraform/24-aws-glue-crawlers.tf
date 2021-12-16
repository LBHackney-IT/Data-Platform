resource "aws_glue_catalog_database" "landing_zone_data_and_insight_address_matching" {
  count = local.is_live_environment ? 1 : 0

  name = "${local.identifier_prefix}-data-and-insight-address-matching-landing-zone"
}

// ==== LANDING ZONE ===========
resource "aws_glue_catalog_database" "landing_zone_catalog_database" {
  name = "${local.identifier_prefix}-landing-zone-database"
}

// ==== RAW ZONE ===========
resource "aws_glue_catalog_database" "raw_zone_unrestricted_address_api" {
  name = "${local.identifier_prefix}-raw-zone-unrestricted-address-api"
}

resource "aws_glue_crawler" "raw_zone_unrestricted_address_api_crawler" {
  tags = module.tags.values

  database_name = aws_glue_catalog_database.raw_zone_unrestricted_address_api.name
  name          = "${local.identifier_prefix}-raw-zone-unrestricted-address-api"
  role          = aws_iam_role.glue_role.arn
  table_prefix  = "unrestricted_address_api_"

  s3_target {
    path       = "s3://${module.raw_zone.bucket_id}/unrestricted/addresses_api/"
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
