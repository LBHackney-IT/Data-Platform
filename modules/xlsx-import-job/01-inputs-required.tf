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

variable "xlsx_import_script_key" {
  description = "XLSX sheets import script key"
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


variable "landing_zone_bucket_id" {
  description = "Landing zone S3 bucket id"
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

variable "department_folder_name" {
  description = "Department folder name"
  type        = string
}

variable "output_folder_name" {
  description = "Output folder name"
  type        = string
}

variable "input_file_name" {
  description = "XLSX input file name"
  type        = string
}

variable "worksheet_name" {
  description = "Name of xlsx worksheet in google drive"
  type        = string
}
