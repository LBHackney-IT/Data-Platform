output "jdbc_connection_name" {
  value = aws_glue_connection.jdbc_database_ingestion.name
}

output "ingestion_database_name" {
  value = aws_glue_catalog_database.ingestion_connection.name
}

output "workflow_name" {
  value = local.workflow_name
}

output "crawler_name" {
  value = aws_glue_crawler.ingestion_database_connection.name
}