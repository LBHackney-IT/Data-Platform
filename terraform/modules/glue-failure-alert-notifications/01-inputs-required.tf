variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type        = string
}

variable "lambda_name" {
  description = "Name of the lambda"
  type        = string
}

variable "lambda_artefact_storage_bucket" {
  description = "The name of the S3 bucket where the lambda artefact will be stored"
  type        = string
}

variable "secrets_manager_kms_key" {
  description = "The KMS Key Id to be used to encrypt the secret which stores the web hook url"
  type = object({
    key_id = string
    arn    = string
  })
}

variable "cloudwatch_event_pattern" {
  description = "A Cloudwatch event pattern to trigger the lambda"
  type        = string
}

variable "secret_name" {
  description = "The name of the secret which stores the web hook url"
  type        = string
}

