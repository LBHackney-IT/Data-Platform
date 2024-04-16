variable "config_file" {
  description = "The configuration file for the file ingestion"
  type        = string
}

variable "department" {
  description = "The department with all its properties"
  type = object({
    identifier            = string
    glue_role_arn         = string
    tags                  = map(string)
    identifier_snake_case = string
    environment           = string
    glue_temp_bucket = object({
      bucket_id = string
    })
    glue_scripts_bucket = object({
      bucket_id = string
    })
    google_service_account = object({
      credentials_secret = object({
        arn = string
      })
    })
  })
}

variable "glue_scripts_bucket_id" {
  description = "Glue scripts bucket id"
  type        = string
}

variable "glue_temp_storage_bucket_id" {
  description = "Glue temporary storage bucket id"
  type        = string
}

variable "helper_module_key" {
  description = "Helpers Python module S3 object key"
  type        = string
}

variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type        = string
}

variable "is_live_environment" {
  description = "A flag indicting if we are running in a live environment for setting up automation"
  type        = bool
}

variable "is_production_environment" {
  description = "A flag indicting if we are running in production for setting up automation"
  type        = bool
}

variable "jars_key" {
  description = "Jars key"
  type        = string
}

variable "landing_zone_bucket_id" {
  description = "Landing zone S3 bucket id"
  type        = string
}

variable "pydeequ_zip_key" {
  description = "Pydeequ module to be used in Glue scripts"
  type        = string
}

variable "raw_zone_bucket_id" {
  description = "Raw zone S3 bucket id"
  type        = string
}

variable "spark_ui_output_storage_id" {
  description = "Id of S3 bucket containing Spark UI output logs"
  type        = string
}

variable "spreadsheet_import_script_key" {
  description = "Spreadsheet import script key"
  type        = string
}
