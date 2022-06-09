variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type        = string
}

variable "lambda_artefact_storage_bucket" {
  type = string
}

variable "output_folder_name" {
  description = "Name of area where data is to be sent in the specified s3 target bucket, e.g. 'housing'"
  type        = string
}

variable "lambda_name" {
  type = string

  validation {
    condition     = length(var.lambda_name) <= 51
    error_message = "The lambda_name must be less than 51 characters long."
  }
}

variable "api_credentials_secret_name" {
  description = "Name of secret in secrets manager containing the API credentials to authenticate"
  type        = string
}

variable "s3_target_bucket_arn" {
  description = "Target S3 bucket arn"
  type        = string
}

variable "s3_target_bucket_name" {
  description = "Target S3 bucket name"
  type        = string
}

variable "s3_target_bucket_kms_key_arn" {
  description = "KMS key arn of S3 target bucket"
  type        = string
}

variable "secrets_manager_kms_key" {
  description = "The KMS Key Id to be used to encrypt the secret which stores the json credentials"
  type = object({
    key_id = string
    arn    = string
  })
}
