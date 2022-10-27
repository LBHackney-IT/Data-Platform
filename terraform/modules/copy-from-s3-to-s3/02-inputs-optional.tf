variable "assume_role" {
  description = "A role to assume when copying the data"
  default     = false
  type        = string
}

variable "lambda_execution_cron_schedule" {
  description = "CRON expression to schedule the Lambda"
  type        = string
  default     = "cron(0 9 * * ? *)"
}

variable "short_identifier_prefix" {
  description = "Environment based identifier prefix"
  type        = string
}
