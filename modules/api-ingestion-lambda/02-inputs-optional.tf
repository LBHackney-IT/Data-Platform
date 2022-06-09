variable "lambda_execution_cron_schedule" {
  description = "CRON expression to schedule the Lambda"
  type        = string
  default     = "cron(0 6 * * ? *)"
}

variable "ephemeral_storage" {
  description = "Amount of temporary storage in MBs"
  type        = number
  default     = 512
}