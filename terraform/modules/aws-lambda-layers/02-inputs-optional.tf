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


variable "compatible_runtimes" {
  description = "List of compatible runtimes for the lambda layer"
  type        = list(string)
  default     = ["python3.10"]
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
