output "rds_snapshot_s3_to_s3_copier_lambda_role_arn" {
  description = "ARN for the s3_to_s3_copier_lambda_role"
  value       = aws_iam_role.rds_snapshot_s3_to_s3_copier_lambda_role.arn
}
