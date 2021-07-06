variable "department_name" {
  type = string
}

variable "identifier_prefix" {
  type = string
}

variable "application" {
  type        = string
  description = "For example, data-platform"
}

variable "google_project_id" {
  type = string
}

variable "secrets_manager_kms_key_id" {
  type        = string
  description = "The KMS Key Id to be used to encrypt the secret which stores the json credentials"
}

variable "tags" {
  description = "AWS tags"
  type        = map(string)
}
