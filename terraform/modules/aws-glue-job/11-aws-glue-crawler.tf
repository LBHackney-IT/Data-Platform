resource "aws_glue_crawler" "crawler" {
  count = var.crawler_details.database_name == null ? 0 : 1
  tags  = local.tags

  database_name = var.crawler_details.database_name
  name          = local.job_name_identifier
  role          = local.glue_role_arn
  table_prefix  = var.crawler_details.table_prefix

  s3_target {
    path = var.crawler_details.s3_target_location

    exclusions = var.glue_crawler_excluded_blobs
  }

  configuration = var.crawler_details.configuration
}

resource "aws_glue_trigger" "crawler_trigger" {
  count = var.crawler_details.database_name == null ? 0 : 1
  tags  = local.tags

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