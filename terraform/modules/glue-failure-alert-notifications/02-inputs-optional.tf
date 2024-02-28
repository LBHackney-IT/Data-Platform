variable "lambda_environment_variables" {
  description = "An object containing environment variables to be used in the Lambda"
  type        = map(string)
}

variable "timeout" {
  description = "The amount of time your Lambda Function has to run in seconds"
  type        = number
  default     = 3
}
