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
        name = string
      })
    })
  })
}

variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type        = string
}

variable "google_sheets_import_script_key" {
  description = "Google sheets import script key"
  type        = string
}

variable "bucket_id" {
  description = "The ID of the bucket to put the dataset"
  type        = string
}

variable "glue_catalog_database_name" {
  description = "The name of the glue catalog database name"
  type        = string
}

variable "dataset_name" {
  description = "Output folder name"
  type        = string
}
