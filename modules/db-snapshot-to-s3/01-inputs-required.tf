variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "project" {
  description = "The project name."
  type        = string
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

variable "landing_zone_kms_key_arn" {
  type = string
}

variable "landing_zone_bucket_arn" {
  type = string
}

variable "landing_zone_bucket_id" {
  type = string
}

variable "rds_instance_ids" {
  type = list(string)
}
