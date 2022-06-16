variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "is_live_environment" {
  description = "A flag indicting if we are running in a live environment for setting up automation"
  type        = bool
}

variable "environment" {
  description = "Environment e.g. Dev, Stg, Prod, Mgmt."
  type        = string
}

variable "glue_scripts_bucket" {
  description = "Glue scripts storage S3 bucket"
  type = object({
    bucket_id   = string
    bucket_arn  = string
    kms_key_arn = string
  })
}

variable "glue_temp_storage_bucket" {
  description = "Glue temporary storage S3 bucket"
  type = object({
    bucket_id   = string
    bucket_arn  = string
    kms_key_arn = string
  })
}

variable "short_identifier_prefix" {
  description = "Project wide short resource identifier prefix"
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