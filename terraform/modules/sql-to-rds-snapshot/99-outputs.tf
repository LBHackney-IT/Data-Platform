# We make any output files clear by adding them to the 99-outputs.tf, meaning anyone can quickly check if they're consuming your module

output "ecr_repository_worker_endpoint" {
  value = module.sql_to_parquet.ecr_repository_worker_endpoint
}

output "rds_instance_id" {
  value = aws_db_instance.ingestion_db.id
}

output "cloudwatch_event_rule_name" {
  value = module.sql_to_parquet.event_rule_names[0]
}
output "cloudwatch_event_rule_arn" {
  value = module.sql_to_parquet.event_rule_arns[0]
}

output "rds_instance_arn" {
  value = aws_db_instance.ingestion_db.arn
}
