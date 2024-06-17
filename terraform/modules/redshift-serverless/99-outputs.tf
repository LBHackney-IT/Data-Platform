output "redshift_serverless_role_arn" {
  value       = aws_iam_role.redshift_serverless_role.arn
  description = "The ARN of the IAM role used by Redshift Serverless."
}

