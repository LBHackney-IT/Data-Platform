variable "function_name" {
  description = "The name of the Lambda function."
  type        = string
}

variable "schedule" {
  description = "The schedule expression. For example, cron(0 20 * * ? *) or rate(5 minutes)."
  type        = string
  validation {
    condition     = can(regex("cron\\(.*\\)", var.schedule)) || can(regex("rate\\(.*\\)", var.schedule))
    error_message = "Schedule must be a valid cron or rate expression."
  }
}

variable "lambda_artefact_storage_bucket" {
  description = "The name of the S3 bucket where the lambda artefact is stored."
  type        = string
}


