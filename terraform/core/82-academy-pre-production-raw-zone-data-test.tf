# Pre-production databases retained after their Academy crawlers are retired.

resource "aws_glue_catalog_database" "revenues_raw_zone_test" {
  count = !local.is_production_environment ? 1 : 0
  name  = "${local.short_identifier_prefix}revenues-raw-zone-test"
}

resource "aws_glue_catalog_database" "bens_housing_needs_raw_zone_test" {
  count = !local.is_production_environment ? 1 : 0
  name  = "${local.short_identifier_prefix}bens-housing-needs-raw-zone-test"
}
