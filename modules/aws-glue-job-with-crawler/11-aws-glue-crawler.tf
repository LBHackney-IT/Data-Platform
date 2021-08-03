
resource "aws_glue_crawler" "crawler" {
  tags = var.tags

  database_name = var.database_name
  name          = "${var.name_prefix}-crawler"
  role          = var.glue_role_arn
  table_prefix  = var.table_prefix

  s3_target {
    path = var.s3_target_location

    exclusions = var.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
    }
  })
}

resource "aws_glue_trigger" "crawler_trigger" {
  tags = var.tags

  name          = "${var.name_prefix}-crawler-trigger"
  type          = "CONDITIONAL"
  workflow_name = var.workflow_name

  predicate {
    conditions {
      job_name = aws_glue_job.job.name
      state    = "SUCCEEDED"
    }
  }

  actions {
    crawler_name = aws_glue_crawler.crawler.name
  }
}