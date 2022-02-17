output "jdbc_connection_name" {
  value = aws_glue_connection.ingestion_database.name
}

output "ingestion_database_name" {
  value = aws_glue_catalog_database.ingestion_database.name
}