#pre-prod setup for testing Academy data

#revenues raw zone test database
resource "aws_glue_catalog_database" "revenues_raw_zone_test" {
  count = !local.is_production_environment ? 1 : 0
  name  = "${local.short_identifier_prefix}revenues-raw-zone-test"
}

#revenues raw zone test crawler
resource "aws_glue_crawler" "revenue_raw_zone_test" {
  count = !local.is_production_environment ? 1 : 0
  tags  = module.tags.values

  database_name = aws_glue_catalog_database.revenues_raw_zone_test[0].name
  name          = "${local.short_identifier_prefix}revenues-raw-zone-test"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path = "s3://${module.raw_zone.bucket_id}/revenues/"
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 3
    }
  })
}

#benefits and housing needs raw zone test database
resource "aws_glue_catalog_database" "bens_housing_needs_raw_zone_test" {
  count = !local.is_production_environment ? 1 : 0
  name  = "${local.short_identifier_prefix}bens-housing-needs-raw-zone-test"
}

#benefits and housing needs raw zone test crawler
resource "aws_glue_crawler" "bens_housing_needs_raw_zone_test" {
  count = !local.is_production_environment ? 1 : 0
  tags  = module.tags.values

  database_name = aws_glue_catalog_database.bens_housing_needs_raw_zone_test[0].name
  name          = "${local.short_identifier_prefix}bens-housing-needs-raw-zone-test"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path = "s3://${module.raw_zone.bucket_id}/benefits-housing-needs/"
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 3
    }
  })
}