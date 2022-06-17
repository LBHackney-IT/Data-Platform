variable "secret_type" {
  description = "Specify the type of secret to store in Secrets Manager"
  type        = string
  default     = "binary"

  validation {
    condition     = contains(["binary", "string"], var.secret_type)
    error_message = "Secret type must be \"binary\" or \"string\"."
  }
}