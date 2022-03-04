resource "aws_glue_catalog_database" "ingestion_database" {
  name = "${var.identifier_prefix}${var.name}"
}

resource "aws_glue_crawler" "ingestion_database_connection" {
  tags = var.tags

  database_name = aws_glue_catalog_database.ingestion_database.name
  name          = "${var.identifier_prefix}${var.name}"
  role          = aws_iam_role.jdbc_connection_crawler_role.arn

  jdbc_target {
    connection_name = aws_glue_connection.ingestion_database.name
    path            = "${local.database_name}/%"
  }

  depends_on = [
    aws_glue_connection.ingestion_database
  ]
}

resource "aws_glue_trigger" "crawler_trigger" {
  tags  = var.tags

  name          = "${var.name}-crawler-trigger"
  type          = "SCHEDULED"
  schedule      = "cron(0 0 6 ? * MON,TUE,WED,THU,FRI *)"

  actions {
    crawler_name = aws_glue_crawler.ingestion_database_connection.name
  }
}
