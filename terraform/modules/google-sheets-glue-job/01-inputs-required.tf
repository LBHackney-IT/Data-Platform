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

variable "is_live_environment" {
  description = "A flag indicting if we are running in a live environment for setting up automation"
  type        = bool
}

variable "is_production_environment" {
  description = "A flag indicting if we are running in production for setting up automation"
  type        = bool
}

variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type        = string
}

variable "glue_scripts_bucket_id" {
  description = "Glue scripts bucket id"
  type        = string
}

variable "google_sheets_import_script_key" {
  description = "Google sheets import script key"
  type        = string
}

variable "helper_module_key" {
  description = "Helpers Python module S3 object key"
  type        = string
}

variable "glue_temp_storage_bucket_url" {
  description = "Glue temp storage S3 bucket url"
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

variable "google_sheets_document_id" {
  description = "Google sheets document id"
  type        = string
}

variable "google_sheets_worksheet_name" {
  description = "Google sheets worksheet name"
  type        = string
}

variable "dataset_name" {
  description = "Output folder name"
  type        = string
}

variable "pydeequ_zip_key" {
  description = "Pydeequ module to be used in Glue scripts"
  type        = string
}

variable "spark_ui_output_storage_id" {
  description = "Id of S3 bucket containing Spark UI output logs"
  type        = string
}
