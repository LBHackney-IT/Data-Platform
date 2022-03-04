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
