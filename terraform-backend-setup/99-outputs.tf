# We make any output files clear by adding them to the 99-outputs.tf, meaning anyone can quickly check if they're consuming your module
output "terraform_state_bucket_arn" {
  description = "Terraform bucket arn"
  value       = aws_s3_bucket.data_platform_terraform_backend.arn
}
