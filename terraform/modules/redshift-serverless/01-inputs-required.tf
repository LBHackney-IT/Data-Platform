variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "identifier_prefix" {
  description = "Prefix"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet ids"
  type        = list(string)
}

variable "secrets_manager_key" {
  description = "ARN of secrets manager KMS key"
  type        = string
}

variable "vpc_id" {
  description = "Id of vpc"
  type        = string
}

variable "namespace_name" {
  description = "Name of the namepsace to be created"
  type        = string
}

variable "workgroup_name" {
  description = "Name of the workgroup to be created"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the workgroup"
  type        = string
}

variable "db_name" {
  description = "name of the database to be created"
  type        = string
}

variable "serverless_compute_usage_limit_period" {
  description = "Serverless compute usage limit period"
  type        = string
  validation {
    condition     = contains(["daily", "weekly", "monthly"], var.serverless_compute_usage_limit_period)
    error_message = "Invalid serverless_compute_usage_limit_period value"
  }
}

variable "serverless_compute_usage_limit_amount" {
  description = "Usage limit amount (RPU)"
  type        = number
}

variable "landing_zone_bucket_arn" {
  description = "ARN of landing zone bucket"
  type        = string
}

variable "refined_zone_bucket_arn" {
  description = "ARN of refined zone bucket"
  type        = string
}


variable "trusted_zone_bucket_arn" {
  description = "ARN of trusted zone bucket"
  type        = string
}

variable "raw_zone_bucket_arn" {
  description = "ARN of raw zone bucket"
  type        = string
}

variable "landing_zone_kms_key_arn" {
  description = "ARN of landing zone KMS key"
  type        = string
}

variable "refined_zone_kms_key_arn" {
  description = "ARN of refined zone KMS key"
  type        = string
}

variable "trusted_zone_kms_key_arn" {
  description = "ARN of trusted zone KMS key"
  type        = string
}

variable "raw_zone_kms_key_arn" {
  description = "ARN of raw zone KMS key"
  type        = string
}
