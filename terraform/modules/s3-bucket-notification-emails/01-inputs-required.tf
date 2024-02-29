variable "name" {
  description = "The name of the SNS topic"
}

variable "bucket_id" {
  description = "The ID of the S3 bucket to subscribe to"
}

variable "bucket_arn" {
  description = "The ARN of the s3 bucket to subscribe to"
}

variable "email_list" {
  description = "A comma separated list of email addresses to subscribe to the SNS topic"
  default     = ""
}

variable "lambda_artefact_storage_bucket" {
  description = "S3 Bucket to store the Lambda artefact in"
}