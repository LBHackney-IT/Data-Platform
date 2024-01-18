variable "identifier_prefix" {
  type        = string
  description = "Environment identifier prefix"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}

variable "compatible_runtimes" {
  description = "List of compatible runtimes for the lambda layer"
  type        = list(string)
  default     = ["python3.10"]
}

variable "environment_variables" {
  type        = map(string)
  description = "Environment Variables to pass to the Lambda Function"
  default     = null
}

variable "install_requirements" {
  type        = bool
  description = "Whether to create and install requirements.txt for the Lambda Function"
  default     = false
}
