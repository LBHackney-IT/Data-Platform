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


variable "lambda_source_dir" {
  description = "Directory containing the Lambda Function source code"
  type        = string
  default     = "../../lambdas/g_drive_to_s3"
}

variable "lambda_output_path" {
  description = "Path to the Lambda artefact zip file"
  type        = string
  default     = "../../lambdas/g_drive_to_s3.zip"
}

variable "lambda_name_underscore" {
  description = "Name of the Lambda function"
  type        = string
  default     = "g_drive_to_s3"
}