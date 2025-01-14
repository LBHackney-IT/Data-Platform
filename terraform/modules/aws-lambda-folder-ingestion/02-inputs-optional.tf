variable "identifier_prefix" {
  type        = string
  description = "Environment identifier prefix"
  default     = ""
}

variable "secret_name" {
  type        = string
  description = "Name of the secret stored in Secrets Manager to grant access to"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}

variable "runtime" {
  type        = string
  description = "Runtime to use for the Lambda Function"
  default     = "python3.11"
  validation {
    condition     = contains(["python3.9", "python3.10", "python3.11"], var.runtime)
    error_message = "Runtime must be a valid Python runtime"
  }

}

variable "lambda_timeout" {
  type        = number
  description = "Amount of time the Lambda Function has to run in seconds"
  default     = 60
  validation {
    condition     = var.lambda_timeout >= 1 && var.lambda_timeout <= 900
    error_message = "Lambda Timeout must be between 1 and 900 seconds"
  }
}

variable "lambda_memory_size" {
  type        = number
  description = "Memory Size for the Lambda Function"
  default     = 128
  validation {
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 10240
    error_message = "Lambda Memory Size must be between 128 and 10240 MB"
  }
}

variable "ephemeral_storage" {
  type        = number
  description = "Additional Ephemeral Storage for the Lambda Function beyond the default 512MB"
  default     = 512
  validation {
    condition     = var.ephemeral_storage >= 512 && var.ephemeral_storage <= 10240
    error_message = "Ephemeral Storage must be between 512 and 10240 MB"
  }
}

variable "lambda_output_path" {
  type        = string
  description = "Path to the Lambda artefact zip file"
  default     = "../../../lambdas/lambda-archives/"
}

variable "environment_variables" {
  type        = map(string)
  description = "Environment Variables to pass to the Lambda Function"
  default     = null
}

variable "output_file_mode" {
  type        = number
  description = "File Mode for the Lambda artefact zip file"
  default     = 0666
}

variable "install_requirements" {
  type        = bool
  description = "Whether to create and install requirements.txt for the Lambda Function"
  default     = false
}
