variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
}

variable "identifier_prefix" {
  description = "A prefix to use for the identifier of the resource."
  type        = string
}

variable "lambda_artefact_storage_bucket" {
  description = "The name of the S3 bucket where the lambda artefact is stored."
  type        = string
}

variable "event_pattern" {
  description = "The event pattern to use for the CloudWatch event rule."
  type        = string
}

variable "lambda_environment_variables" {
  description = "A mapping of environment variables to assign to the lambda."
  type        = map(string)
}

variable "secrets_manager_kms_key" {
  description = "The KMS Key Id to be used to encrypt the secret which stores the web hook url."
  type = object({
    key_id = string
    arn    = string
  })
}

variable "secret_name" {
  description = "The name of the secret to be retrieved from AWS Secrets Manager."
  type        = string
}

variable "event_input" {
  description = "JSON string passed to the target Lambda function."
  type        = string
  default     = ""
}
