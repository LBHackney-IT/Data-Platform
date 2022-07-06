data "aws_glue_crawler" "crawler" {
  count = var.crawler_details.database_name == null ? 0 : 1
  name  = local.job_name_identifier
}

data "aws_glue_trigger" "crawler_trigger" {
  count = var.crawler_details.database_name == null ? 0 : 1
  name  = "${local.job_name_identifier}-crawler-trigger"
}