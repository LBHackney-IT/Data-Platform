output "rds_snapshot_s3_to_s3_copier_lambda_role_arn" {
  description = "ARN for the s3_to_s3_copier_lambda_role"
  value       = aws_iam_role.rds_snapshot_s3_to_s3_copier_lambda_role.arn
}

output "rds_snapshot_s3_to_s3_copier_lambda_name" {
  description = "Name for the s3_to_s3_copier_lambda"
  value       = module.rds_snapshot_s3_to_s3_copier.lambda_name
}

output "export_rds_to_s3_snapshot_lambda_name" {
  description = "Name for the export_rds_to_s3_snapshot_lambda"
  value       = module.trigger_rds_snapshot_export.lambda_name
}
