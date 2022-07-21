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
  })
}

variable "glue_catalog_database_name" {
  description = "The name of the glue catalog database name"
  type        = string
}

variable "spreadsheet_import_script_key" {
  description = "Spreadsheet import script key"
  type        = string
}

variable "raw_zone_bucket_id" {
  description = "Raw zone S3 bucket id"
  type        = string
}

variable "glue_job_name" {
  description = "Name of AWS Glue job"
  type        = string
}

variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type        = string
}

variable "output_folder_name" {
  description = "Output folder name"
  type        = string
}

variable "data_set_name" {
  description = "Data set name"
  type        = string
}

variable "worksheet_name" {
  description = "Name of spreadsheet worksheet in google drive"
  type        = string
}

variable "is_production_environment" {
  description = "A flag indicting if we are running in production for setting up automation"
  type        = bool
}

variable "is_live_environment" {
  description = "A flag indicting if we are running in a live environment for setting up automation"
  type        = bool
}
