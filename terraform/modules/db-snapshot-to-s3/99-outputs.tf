# We make any output files clear by adding them to the 99-outputs.tf, meaning anyone can quickly check if they're consuming your module
output "s3_to_s3_copier_lambda_role_arn" {
  description = "KMS Key arn"
  value       = aws_iam_role.s3_to_s3_copier_lambda.arn
}

output "rds_snapshot_service_arn" {
  description = "RDS Snapshot Service ARN"
  value       = aws_iam_role.rds_snapshot_export_service.arn
}
