variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type        = string
}

variable "lambda_artefact_storage_bucket_name" {
  description = "Name of bucket to storage the lambda code in"
  type        = string
}

variable "s3_bucket_id" {
  description = "Bucket ID (Name) for the destination s3 bucket"
  type        = string
}

variable "s3_bucket_arn" {
  description = "Bucket ARN for the destination s3 bucket"
  type        = string
}

variable "s3_bucket_kms_key_arn" {
  description = "KMS Key ARN for the key that encrypts the destination s3 bucket"
  type        = string
}

variable "run_daily" {
  description = "If set to true the lambda will run on a daily schedule"
  type        = bool
}

