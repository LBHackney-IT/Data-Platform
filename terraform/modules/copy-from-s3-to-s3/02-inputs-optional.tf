variable "assume_role" {
  description = "A role to assume when copying the data"
  default     = false
  type        = string
}

variable "lambda_name" {
  description = "The name to give the lambda"
  default     = "copy-from-s3-to-s3"
  type        = string
}