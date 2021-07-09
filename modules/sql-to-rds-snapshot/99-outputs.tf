# We make any output files clear by adding them to the 99-outputs.tf, meaning anyone can quickly check if they're consuming your module

output "ecr_repository_worker_endpoint" {
  value = aws_ecr_repository.worker.repository_url
}

output "rds_instance_id" {
  value = aws_db_instance.ingestion_db.id
}
