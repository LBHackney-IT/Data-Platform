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
  type = string
}

variable "s3_target_bucket_id" {
  description = "Name of the bucket where the file should be moved to"
  type        = string
}

variable "s3_target_bucket_kms_key_arn" {
  type = string
}

variable "secrets_manager_kms_key" {
  description = "The KMS Key Id to be used to encrypt the secret which stores the json credentials"
  type = object({
    key_id = string
    arn    = string
  })
}

variable "file_id" {
  type = string
}

variable "file_name" {
  type = string
}

variable "service_area" {
  description = "Name of service area where data is to be sent, e.g. 'housing'"
  type        = string
}

variable "department_identifier" {
  description = "Department identifier"
  type        = string
}

variable "sftp_server_credentials" {
  description = "name of secret storing sftp server credentials"
  type        = string
}


