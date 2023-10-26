variable "workflow_name" {
  description = "Optional. The name of a workflow to run on completion. This workflow will be run after each database has been added to s3"
  type        = string
  default     = ""
}

variable "workflow_arn" {
  description = "Optional. The arn of a workflow to run on completion. This workflow will be run after each database has been added to s3"
  type        = string
  default     = ""
}

variable "backdated_workflow_name" {
  description = "Optional. The name of a workflow to run on completion. This workflow will be run after each database has been added to s3 for backdated data ingestion"
  type        = string
  default     = ""
}

variable "backdated_workflow_arn" {
  description = "Optional. The arn of a workflow to run on completion. This workflow will be run after each database has been added to s3 for backdated data ingestion"
  type        = string
  default     = ""
}

variable "aws_account_suffix" {
  description = "Optional. Suffix to be used for certain resources such as S3 buckets to avoid conflicts with existing setups. This is primarily for development purposes on sandbox account"
  type        = string
  default     = ""
}

variable "source_prefix" {
  description = "Prefix to be used for the source bucket location"
  type        = string
  default     = ""
}

variable "target_prefix" {
  description = "Prefix to be used for the target bucket location"
  type        = string
  default     = ""
}
