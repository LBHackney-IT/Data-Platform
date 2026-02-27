resource "aws_glue_crawler" "crawler" {
  tags = var.tags

  database_name = var.glue_database_name
  name          = "${var.short_identifier_prefix}event-streaming-topics-crawler"
  role          = var.glue_iam_role

  s3_target {
    path = "s3://${var.s3_bucket_to_write_to.bucket_id}/event-streaming/"

    exclusions = ["*.json", "*.txt", "*.zip", "*.xlsx"]
  }

  schema_change_policy {
    delete_behavior = "DELETE_FROM_DATABASE"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  configuration = jsonencode({
    Version = 1.0,
    Grouping = {
      TableGroupingPolicy     = "CombineCompatibleSchemas"
      TableLevelConfiguration = 3
    }
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
    }
  })
}