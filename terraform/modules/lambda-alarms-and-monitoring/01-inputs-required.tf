variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type        = string
}

variable "lambda_name" {
  description = "Name of the lambda"
  type        = string
}

variable "project" {
  description = "The project name."
  type        = string
}

variable "environment" {
  description = "Environment e.g. Dev, Stg, Prod, Mgmt."
  type        = string
}

variable "alarms_handler_lambda_name" {
  description = "Name of the alarms handler lambda"
  type        = string
}

variable "alarms_handler_lambda_arn" {
  description = "ARN of the alarms handler lambda"
  type        = string
}
