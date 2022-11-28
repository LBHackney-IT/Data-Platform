resource "aws_glue_catalog_database" "ingestion_connection" {
  name = "${var.identifier_prefix}${var.name}"
  
  lifecycle {
    prevent_destroy = true
  }
}

locals {
  jdbc_target_path = var.schema_name != null ? "${local.database_name}/${var.schema_name}/%" : "${local.database_name}/%"
  workflow_name    = var.create_workflow ? aws_glue_workflow.database_ingestion[0].name : null
}

resource "aws_glue_crawler" "ingestion_database_connection" {
  tags = var.tags

  database_name = aws_glue_catalog_database.ingestion_connection.name
  name          = "${var.identifier_prefix}${var.name}"
  role          = aws_iam_role.jdbc_connection_crawler_role.arn

  jdbc_target {
    connection_name = aws_glue_connection.jdbc_database_ingestion.name
    path            = local.jdbc_target_path
  }

  depends_on = [
    aws_glue_connection.jdbc_database_ingestion
  ]
}

resource "aws_glue_workflow" "database_ingestion" {
  count = var.create_workflow ? 1 : 0
  tags  = var.tags

  name = "${var.identifier_prefix}${var.name}"
}

resource "aws_glue_trigger" "ingestion_crawler" {
  tags = var.tags

  name          = "${var.identifier_prefix}${var.name}"
  type          = "SCHEDULED"
  schedule      = var.job_schedule
  workflow_name = local.workflow_name

  actions {
    crawler_name = aws_glue_crawler.ingestion_database_connection.name
  }
}
