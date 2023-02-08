variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type        = string
}

variable "lambda_artefact_storage_bucket" {
  type = object({
    bucket_id   = string
    bucket_arn  = string
    kms_key_arn = string
  })
}

variable "origin_bucket" {
  type = object({
    bucket_id   = string
    bucket_arn  = string
    kms_key_arn = string
  })
}

variable "origin_path" {
  type = string
}

variable "target_bucket" {
  type = object({
    bucket_id   = string
    bucket_arn  = string
    kms_key_arn = string
  })
}

variable "target_path" {
  type = string
}

variable "lambda_name" {
  description = "The name to give the lambda"
  type        = string
}

variable "is_live_environment" {
  description = "A flag indicting if we are running in a live environment for setting up automation"
  type        = bool
}

variable "short_identifier_prefix" {
  description = "Environment based identifier prefix"
  type        = string
}

variable "environment" {
  description = "Name of the current environment"
  type        = string
}

variable "is_production_environment" {
  description = "A flag indicating if we are running in production environment"
  type        = string
}

