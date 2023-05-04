# Tags
variable "application" {
  description = "Name of the application."
  type        = string
  default     = "DataPlatform"
}

variable "department" {
  description = "Name of the department responsible for the service."
  type        = string
  default     = "HackIT"
}

variable "automation_build_url" {
  description = "The project automation build url."
  type        = string
  default     = "Unknown"
}

variable "confidentiality" {
  description = "The project confidentiality status"
  type        = string
  default     = "Public"
}

variable "custom_tags" {
  description = "Map of custom tags (merged and added to existing other Tags). Must not overlap with any already defined tags."
  type        = map(string)
  default     = {}
}

variable "phase" {
  description = "The project phase."
  type        = string
  default     = "Default"
}

variable "project" {
  description = "The project name."
  type        = string
  default     = "Internal"
}

variable "stack" {
  description = "The project stack."
  type        = string
  default     = "ChangeMe"
}

variable "team" {
  description = "Name of the team responsible for the service."
  type        = string
  default     = "ChangeMe"
}

# Project Variable
variable "rds_instance_ids" {
  description = "Array of rds instance ids"
  type        = list(string)
  default     = []
}

variable "aws_api_vpc_id" {
  description = "Staging APIs peer VPC ID"
  type        = string
  default     = ""
}

variable "email_to_notify" {
  description = "Email to notify when Glue jobs fail. This is only for local development"
  type        = string
  default     = null
}

variable "copy_liberator_to_pre_prod_lambda_execution_role" {
  description = "AWS IAM role name to assume for triggering the lambda to copy liberator data to pre-prod"
  type        = string
  default     = null
}

variable "pre_production_liberator_data_storage_kms_key_arn" {
  description = "KMS Key ARN for the liberator data storage bucket in pre production"
  type        = string
  default     = null
}
