variable "workflow_names" {
  description = "A list of workflow names to be triggered after import"
  type        = list(string)
  default     = []
}

variable "workflow_arns" {
  description = "A list of workflow arns to be triggered after import"
  type        = list(string)
  default     = []
}

variable "ingestion_schedule_enabled" {
  description = "Flag to enable the cloud watch trigger to copy the data from g-drive to s3"
  type        = bool
  default     = true
}
