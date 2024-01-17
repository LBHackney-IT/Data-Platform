variable "lambda_name" {
  type        = string
  description = "Name of the Lambda Function"
}

variable "layer_zip_file" {
  description = "The name of the zip file filename.zip"
  type        = string
}

variable "layer_name" {
  description = "Name of the lambda layer"
  type        = string
}

