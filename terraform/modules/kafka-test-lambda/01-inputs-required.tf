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

variable "kafka_cluster_config" {
  type = object({
    zookeeper_connect_string = string
    bootstrap_brokers        = string
    bootstrap_brokers_tls    = string
    vpc_security_groups      = list
    vpc_subnets              = string
    cluster_name             = string
    cluster_arn              = string
  })
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
