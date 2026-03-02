variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type        = string
}

variable "lambda_artefact_storage_bucket" {
  type = string
}

variable "kafka_cluster_arn" {
  type = string
}

variable "kafka_cluster_kms_key_arn" {
  type = string
}

variable "kafka_cluster_name" {
  type = string
}

variable "kafka_security_group_id" {
  type = list(string)
}

variable "lambda_name" {
  type = string

  validation {
    condition     = length(var.lambda_name) <= 51
    error_message = "The lambda_name must be less than 51 characters long."
  }
}

variable "lambda_environment_variables" {
  description = "An object containing environment variables to be used in the Lambda"
  type        = map(string)
}

variable "vpc_id" {
  description = "VPC ID to deploy the kafta instance into"
  type        = string
}

variable "subnet_ids" {
  type = list(string)
}
