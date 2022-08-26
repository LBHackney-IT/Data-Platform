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

variable "lambda_name" {
  type = string

  validation {
    condition     = length(var.lambda_name) <= 51
    error_message = "The lambda_name must be less than 51 characters long."
  }
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

variable "api_credentials_secret_name" {
  description = "Name of secret in secrets manager containing the API credentials to authenticate"
  type        = string
}

variable "secrets_manager_kms_key" {
  description = "The KMS Key Id to be used to encrypt the secret which stores the json credentials"
  type = object({
    key_id = string
    arn    = string
  })
}

variable "lambda_environment_variables" {
  description = "An object containing environment variables to be used in the Lambda"
  type        = map(string)
}

variable "lambda_handler" {
  description = "name of the file and main lambda function"
  type        = string
}

variable "runtime_language" {
  description = "the language of the lambda function"
  type        = string
  validation {
    condition = (
      contains([
        "python3.8",
        "nodejs14.x"
      ], var.runtime_language)
    )
    error_message = "The value cannot be a blank string, and must be one of the following: 'python3.8' or 'nodejs14.x'"
  }
}

variable "is_production_environment" {
  description = "A flag indicting if we are running in production for setting up automation"
  type        = bool
}

variable "is_live_environment" {
  description = "A flag indicting if we are running in a live environment for setting up automation"
  type        = bool
}
