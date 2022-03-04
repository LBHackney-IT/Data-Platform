output "jdbc_connection_name" {
  value = aws_glue_connection.ingestion_database.name
}

output "ingestion_database_name" {
  value = aws_glue_catalog_database.ingestion_database.name
}

output "workflow_name" {
  value = aws_glue_workflow.database_ingestion.name
}

output "crawler_name" {
  value = aws_glue_crawler.ingestion_database_connection.name
}