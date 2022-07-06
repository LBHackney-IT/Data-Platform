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

variable "landing_zone_bucket" {
  description = "Landing zone S3 bucket"
  type = object({
    bucket_id   = string
    bucket_arn  = string
    kms_key_arn = string
  })
}

variable "raw_zone_bucket" {
  description = "Raw zone S3 bucket"
  type = object({
    bucket_id   = string
    bucket_arn  = string
    kms_key_arn = string
  })
}

variable "refined_zone_bucket" {
  description = "Refined zone S3 bucket"
  type = object({
    bucket_id   = string
    bucket_arn  = string
    kms_key_arn = string
  })
}

variable "trusted_zone_bucket" {
  description = "Trusted zone S3 bucket"
  type = object({
    bucket_id   = string
    bucket_arn  = string
    kms_key_arn = string
  })
}

variable "athena_storage_bucket" {
  description = "Athena storage S3 bucket"
  type = object({
    bucket_id   = string
    bucket_arn  = string
    kms_key_arn = string
  })
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

variable "spark_ui_output_storage_bucket" {
  description = "Spark UI Output Storage"
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

variable "application" {
  description = "For example, data-platform"
  type        = string
}

variable "secrets_manager_kms_key" {
  description = "The KMS Key Id to be used to encrypt the secret which stores the json credentials"
  type = object({
    key_id = string
    arn    = string
  })
}

variable "sso_instance_arn" {
  description = "The ARN of the SSO Instance used to configure SSO on the main HackIT account"
  type        = string
}

variable "identity_store_id" {
  description = "The ID of the Identity Store used to configure SSO on the main HackIT account"
  type        = string
}

variable "redshift_ip_addresses" {
  type        = list(string)
  description = "Public IP addresses for the redshift cluster"
}

variable "redshift_port" {
  description = "Port that the redshift cluster is running on"
  type        = number
}

variable "glue_failure_notification_lambda_arn" {
  description = "Arn of the lambda that will publish to the glue failure notification sns topic"
  type        = string
}