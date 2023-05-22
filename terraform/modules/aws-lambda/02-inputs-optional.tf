variable "identifier_prefix" {
  type        = string
  description = "Environment identifier prefix"
  default     = ""
}

variable "enable_kms_key_access" {
  type        = bool
  description = "Grants KMS Key Access to the Lambda Role"
  default     = false
}

variable "enable_secrets_manager_access" {
  type        = bool
  description = "Grants Secrets Manager Access to the Lambda Role"
  default     = false
}

variable "secret_name" {
  type        = string
  description = "Name of the secret stored in Secrets Manager to grant access to"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}

variable "runtime" {
  type        = string
  description = "Runtime to use for the Lambda Function"
  default     = "python3.8"
}

variable "lambda_timeout" {
  type        = number
  description = "Amount of time the Lambda Function has to run in seconds"
  default     = 60
}

variable "lambda_memory_size" {
  type        = number
  description = "Memory Size for the Lambda Function"
  default     = 128
}

variable "ephemeral_storage" {
  type        = number
  description = "Additional Ephemeral Storage for the Lambda Function beyond the default 512MB"
  default     = 512
}

variable "lambda_output_path" {
  type        = string
  description = "Path to the Lambda artefact zip file"
  default     = "../../../lambdas/lambda-archives/"
}

variable "environment_variables" {
  type        = map(string)
  description = "Environment Variables to pass to the Lambda Function"
  default     = null
}

variable "output_file_mode" {
  type        = number
  description = "File Mode for the Lambda artefact zip file"
  default     = 0666
}
