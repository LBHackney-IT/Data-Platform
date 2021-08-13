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

variable "zone_kms_key_arn" {
  type = string
}

variable "zone_bucket_arn" {
  type = string
}

variable "tascomi_public_key" {
  type        = string
  description = "Tascomi api Public key"
}

variable "tascomi_private_key" {
  type        = string
  description = "Tascomi api Private key"
}

variable "resource_name" {
  type = string
}

variable "zone_bucket_id" {
  description = "Name of the bucket where the file should be moved to"
  type        = string
}

variable "glue_role_arn" {
  description = "Glue role arn"
  type        = string
}
#
variable "glue_scripts_bucket_id" {
  description = "Glue scripts bucket id"
  type        = string
}

variable "glue_temp_storage_bucket_id" {
  description = "Id of temp glue job storage"
  type        = string
}

variable "helpers_script_key" {
  description = "Helpers script key"
  type        = string
}

# variable "refined_zone_bucket_id" {
#   description = "Refined zone bucket id"
#   type        = string
# }
#
variable "glue_catalog_database_name" {
  description = "Glue zone catalog database name"
  type        = string
}
# # variable "lambda_name" {
# #   type = string
# #   # validation {
# #   #   condition     = length(var.lambda_name) <= 51
# #   #   error_message = "The lambda_name must be less than 51 characters long."
# #   # }
# # }
#
variable "service_area" {
  description = "Name of service area where data is to be sent, e.g. 'housing'"
  type        = string
}
