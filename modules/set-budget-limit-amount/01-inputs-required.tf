variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "environment" {
  description = "Enviroment e.g. Dev, Stg, Prod, Mgmt."
  type        = string
}

variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type        = string
}

variable "lambda_artefact_storage_bucket" {
  type = string
}

variable "lambda_name" {
  type = string

  validation {
    condition     = length(var.lambda_name) <= 51
    error_message = "The lambda_name must be less than 51 characters long."
  }
}

variable "service_area" {
  description = "Name of service area where data is to be sent, e.g. 'housing'"
  type        = string
}

variable "account_id" {
  description = "Account ID associated with budget being updated"
  type        = string
}