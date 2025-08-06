variable "department_identifier" {
  description = "Department identifier"
  type        = string
}

variable "environment" {
  description = "Environment (prod/stg)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "identifier_prefix" {
  description = "Identifier prefix for resource naming"
  type        = string
}

variable "short_identifier_prefix" {
  description = "Short identifier prefix for resource naming"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "bucket_configs" {
  description = "S3 bucket configurations"
  type = object({
    landing_zone_bucket = object({
      bucket_arn  = string
      kms_key_arn = string
    })
    raw_zone_bucket = object({
      bucket_arn  = string
      kms_key_arn = string
    })
    refined_zone_bucket = object({
      bucket_arn  = string
      kms_key_arn = string
    })
    trusted_zone_bucket = object({
      bucket_arn  = string
      kms_key_arn = string
    })
    athena_storage_bucket = object({
      bucket_arn  = string
      kms_key_arn = string
    })
    glue_scripts_bucket = object({
      bucket_arn  = string
      kms_key_arn = string
    })
    spark_ui_output_storage_bucket = object({
      bucket_arn  = string
      kms_key_arn = string
    })
    glue_temp_storage_bucket = object({
      bucket_arn  = string
      kms_key_arn = string
    })
  })
}

variable "mwaa_key_arn" {
  description = "MWAA KMS key ARN"
  type        = string
}

variable "mwaa_etl_scripts_bucket_arn" {
  description = "MWAA ETL scripts bucket ARN"
  type        = string
}

variable "secrets_manager_kms_key_arn" {
  description = "Secrets Manager KMS key ARN"
  type        = string
}

variable "redshift_secret_arn" {
  description = "Redshift cluster credentials secret ARN"
  type        = string
}

variable "google_service_account_secret_arn" {
  description = "Google service account credentials secret ARN"
  type        = string
}

variable "create_airflow_user" {
  description = "Whether to create departmental airflow user"
  type        = bool
  default     = false
}

variable "create_notebook" {
  description = "Whether to create notebook resources"
  type        = bool
  default     = false
}

variable "additional_s3_access" {
  description = "Additional S3 access configurations"
  type = list(object({
    bucket_arn  = string
    kms_key_arn = string
    paths       = optional(list(string))
    actions     = list(string)
  }))
  default = []
}

variable "cloudtrail_bucket" {
  description = "CloudTrail bucket configuration (for data-and-insight department only)"
  type = object({
    bucket_arn  = string
    kms_key_arn = string
  })
  default = null
}

# Notebook-related variables (only used if create_notebook is true)
variable "notebook_role_arn" {
  description = "Notebook role ARN (required if create_notebook is true)"
  type        = string
  default     = ""
}

variable "notebook_arn" {
  description = "Notebook ARN (required if create_notebook is true)"
  type        = string
  default     = ""
}

variable "lifecycle_configuration_arn" {
  description = "Lifecycle configuration ARN (required if create_notebook is true)"
  type        = string
  default     = ""
}

variable "notebook_name" {
  description = "Notebook name (required if create_notebook is true)"
  type        = string
  default     = ""
}