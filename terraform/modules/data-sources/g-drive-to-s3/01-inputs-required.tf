
variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type        = string
}

variable "lambda_name" {
  type = string

  validation {
    condition     = length(var.lambda_name) <= 51
    error_message = "The lambda_name must be less than 51 characters long."
  }
}