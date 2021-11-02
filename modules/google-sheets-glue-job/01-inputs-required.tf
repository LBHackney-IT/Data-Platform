variable "department" {
  description = "The department with all its properties"
  type = object({
    identifier    = string
    glue_role_arn = string
    tags          = map(string)
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

variable "helpers_script_key" {
  description = "Helpers script key"
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
