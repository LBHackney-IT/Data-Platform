variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "is_live_environment" {
  description = "A flag indicting if we are running in a live environment for setting up automation"
  type        = bool
}

variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type        = string
}

variable "glue_role_arn" {
  description = "Glue role arn"
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

variable "glue_temp_storage_bucket_id" {
  description = "Glue temporary storage bucket id"
  type        = string
}

variable "sheets_credentials_name" {
  description = "Google sheets credentials"
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

variable "glue_job_name" {
  description = "Name of AWS Glue job"
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

variable "department_name" {
  description = "Department folder name"
  type        = string
}

variable "dataset_name" {
  description = "Output folder name"
  type        = string
}
