resource "aws_glue_crawler" "crawler" {
  count = var.crawler_details == null ? 0 : 1
  tags  = var.department.tags

  database_name = var.crawler_details.database_name
  name          = local.job_name_identifier
  role          = var.department.glue_role_arn
  table_prefix  = var.table_prefix

  s3_target {
    path = var.crawler_details.s3_target_location

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
  count = var.crawler_details == null ? 0 : 1
  tags  = var.department.tags

  name          = "${local.job_name_identifier}-crawler-trigger"
  type          = "CONDITIONAL"
  workflow_name = var.workflow_name

  predicate {
    conditions {
      job_name = aws_glue_job.job.name
      state    = "SUCCEEDED"
    }
  }

  actions {
    crawler_name = aws_glue_crawler.crawler[0].name
  }
}