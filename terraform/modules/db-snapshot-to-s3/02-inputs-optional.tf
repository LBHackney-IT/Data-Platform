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