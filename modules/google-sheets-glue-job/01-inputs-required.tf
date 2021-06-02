variable "tags" {
  description = "AWS tags"
  type        = map(string)
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

variable "glue_temp_storage_bucket_id" {
  description = "Glue temporary storage bucket id"
  type        = string
}

variable "sheets_credentials_name" {
  description = "Google sheets credentials"
  type        = string
}

variable "landing_zone_bucket_id" {
  description = "Landing zone S3 bucket id"
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

variable "department_folder_name" {
  description = "Department folder name"
  type        = string
}

variable "output_folder_name" {
  description = "Output folder name"
  type        = string
}


