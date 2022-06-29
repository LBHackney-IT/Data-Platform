# We make any output files clear by adding them to the 99-outputs.tf, meaning anyone can quickly check if they're consuming your module
output "bucket_id" {
  description = "Bucket id of bucket"
  value       = aws_s3_bucket.bucket.bucket
}

output "bucket_arn" {
  description = "Bucket id of bucket"
  value       = aws_s3_bucket.bucket.arn
}

output "kms_key_id" {
  description = "KMS Key id"
  value       = aws_kms_key.key.id
}

output "kms_key_arn" {
  description = "KMS Key arn"
  value       = aws_kms_key.key.arn
}

output "bucket_url" {
  description = "S3 bucket url"
  value       = "s3://${aws_s3_bucket.bucket.bucket}"
}
