resource "aws_glue_crawler" "trusted_zone_housing_repairs_crawler" {
  tags = module.department_housing_repairs.tags

  database_name = module.department_housing_repairs.trusted_zone_catalog_database_name
  name          = "${local.short_identifier_prefix}trusted-zone-housing-repairs"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path       = "s3://${module.trusted_zone.bucket_id}/housing-repairs/repairs/"
    exclusions = local.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    }
  })
}

resource "aws_glue_trigger" "housing_repairs_trusted_crawler" {
  tags = module.department_housing_repairs.tags

  name     = "${local.short_identifier_prefix}housing-repairs-repairs-trusted-crawler-trigger"
  schedule = "cron(0 7,8,9,10 ? * MON-FRI *)"
  type     = "SCHEDULED"
  enabled  = local.is_live_environment

  actions {
    crawler_name = aws_glue_crawler.trusted_zone_housing_repairs_crawler.name
  }
}
