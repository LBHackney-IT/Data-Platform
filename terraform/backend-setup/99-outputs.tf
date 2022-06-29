# We make any output files clear by adding them to the 99-outputs.tf, meaning anyone can quickly check if they're consuming your module
output "terraform_state_storage_arn" {
  description = "Terraform bucket arn"
  value       = aws_s3_bucket.terraform_state_storage.arn
}
