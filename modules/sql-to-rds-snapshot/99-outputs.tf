# We make any output files clear by adding them to the 99-outputs.tf, meaning anyone can quickly check if they're consuming your module

output "ecr_repository_worker_endpoint" {
  value = aws_ecr_repository.worker.repository_url
}

output "rds_instance_id" {
  value = aws_db_instance.ingestion_db.id
}

output "cloudwatch_event_rule_name" {
  value = aws_cloudwatch_event_rule.new_s3_object.name
}
output "cloudwatch_event_rule_arn" {
  value = aws_cloudwatch_event_rule.new_s3_object.arn
}
