variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "is_live_environment" {
  description = "A flag indicting if we are running in a live environment for setting up automation"
  type        = bool
}

variable "landing_zone_bucket_id" {
  description = "Landing zone S3 bucket id"
  type        = string
}

variable "raw_zone_bucket_id" {
  description = "Raw zone S3 bucket id"
  type        = string
}

variable "refined_zone_bucket_id" {
  description = "Refined zone S3 bucket id"
  type        = string
}

variable "trusted_zone_bucket_id" {
  description = "Trusted zone S3 bucket id"
  type        = string
}

variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type        = string
}

variable "name" {
  description = "The name of the department"
  type        = string
}

variable "application" {
  type        = string
  description = "For example, data-platform"
}

variable "secrets_manager_kms_key_id" {
  type        = string
  description = "The KMS Key Id to be used to encrypt the secret which stores the json credentials"
}
