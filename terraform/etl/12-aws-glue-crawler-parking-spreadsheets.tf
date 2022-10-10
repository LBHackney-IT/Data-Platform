resource "aws_glue_crawler" "raw_zone_parking_g_drive_crawler" {
  tags = module.department_parking_data_source.tags

  database_name = module.department_parking_data_source.raw_zone_catalog_database_name
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
  tags = module.department_parking_data_source.tags

  name     = "${local.short_identifier_prefix}parking-raw-g-drive-crawler-trigger"
  schedule = "cron(0 23 * * ? *)"
  type     = "SCHEDULED"
  enabled  = local.is_live_environment

  actions {
    crawler_name = aws_glue_crawler.raw_zone_parking_g_drive_crawler.name
  }
}