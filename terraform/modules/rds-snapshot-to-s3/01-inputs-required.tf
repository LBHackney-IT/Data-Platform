variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "project" {
  description = "The project name."
  type        = string
}

variable "environment" {
  description = "Environment e.g. Dev, Stg, Prod, Mgmt."
  type        = string
}

variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type        = string
}

variable "lambda_artefact_storage_bucket" {
  type = string
}

variable "zone_kms_key_arn" {
  type = string
}

variable "zone_bucket_arn" {
  type = string
}

variable "zone_bucket_id" {
  type = string
}

variable "service_area" {
  description = "Name of service area where data is to be sent, e.g. 'housing'"
  type        = string
}

variable "rds_instance_ids" {
  type = list(string)
}

variable "rds_instance_arns" {
  type = list(string)
}
