variable "lambda_name" {
  type        = string
  description = "Name of the Lambda Function"
}

variable "layer_zip_path" {
  description = "Path to the lambda layer zip file"
  type        = string
}

variable "layer_name" {
  description = "Name of the lambda layer"
  type        = string
}

