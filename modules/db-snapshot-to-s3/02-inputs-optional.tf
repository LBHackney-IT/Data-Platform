variable "workflow_name" {
  description = "Optional. The name of a workflow to run on completion. This workflow will be run after each database has been added to s3"
  type        = string
  default     = ""
}

variable "workflow_arn" {
  description = "Optional. The arn of a workflow to run on completion. This workflow will be run after each database has been added to s3"
  type        = string
  default     = "arn:aws:glue:eu-west-2:123:not-a-glue-job"
}