variable "lambda_name" {
  type        = string
  description = "Name of the Lambda Function"
}

variable "handler" {
  type        = string
  description = "Function entrypoint in the format of file.function"
}

variable "lambda_artefact_storage_bucket" {
  type        = string
  description = "S3 Bucket to store the Lambda artefact in"
}

variable "s3_key" {
  type        = string
  description = "S3 Key to store the Lambda artefact in"
}

variable "lambda_source_dir" {
  type        = string
  description = "Directory containing the Lambda Function source code"
}





