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

variable "glue_scripts_bucket_id" {
  description = "Glue scripts bucket id"
  type        = string
}

variable "xlsx_import_script_key" {
  description = "XLSX sheets import script key"
  type        = string
}

variable "helper_module_key" {
  description = "Helpers Python module S3 object key"
  type        = string
}

variable "jars_key" {
  description = "Jars key"
  type        = string
}

variable "glue_temp_storage_bucket_id" {
  description = "Glue temporary storage bucket id"
  type        = string
}

variable "lambda_artefact_storage_bucket" {
  type = string
}

variable "landing_zone_bucket_id" {
  description = "Landing zone S3 bucket id"
  type        = string
}

variable "landing_zone_kms_key_arn" {
  type = string
}

variable "identifier_prefix" {
  type = string
}

variable "landing_zone_bucket_arn" {
  type = string
}

variable "google_sheets_document_id" {
  description = "Google sheets document id"
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

variable "output_folder_name" {
  description = "Output folder name"
  type        = string
}

variable "input_file_name" {
  description = "XLSX input file name"
  type        = string
}

variable "worksheets" {
  type = map(
    object({
      header_row_number = number
      worksheet_name    = string
    })
  )
}

variable "pydeequ_zip_key" {
  description = "Pydeequ module to be used in Glue scripts"
  type        = string
}
