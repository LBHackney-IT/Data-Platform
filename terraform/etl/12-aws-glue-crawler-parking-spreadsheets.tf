resource "aws_glue_crawler" "raw_zone_parking_g_drive_crawler" {
  count = !local.is_production_environment ? 1 : 0
  tags  = module.department_parking_data_source.tags

  database_name = aws_glue_catalog_database.parking_raw_zone_manual_catalog_database[0].name
  name          = "${local.short_identifier_prefix}raw-zone-parking-g-drive"
  role          = data.aws_iam_role.glue_role.arn

  s3_target {
    path       = "s3://${module.raw_zone_data_source.bucket_id}/parking/g-drive"
    exclusions = local.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 4
    }
  })
}

resource "aws_glue_trigger" "raw_zone_parking_spreadsheets_crawler" {
  count = !local.is_production_environment ? 1 : 0
  tags  = module.department_parking_data_source.tags

  name     = "${local.short_identifier_prefix}parking-raw-g-drive-crawler-trigger"
  schedule = "cron(0 23 * * ? *)"
  type     = "SCHEDULED"
  enabled  = !local.is_production_environment

  actions {
    crawler_name = aws_glue_crawler.raw_zone_parking_g_drive_crawler[0].name
  }
}