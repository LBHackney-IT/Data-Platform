output "jdbc_connection_name" {
  value = aws_glue_connection.ingestion_database.name
}
