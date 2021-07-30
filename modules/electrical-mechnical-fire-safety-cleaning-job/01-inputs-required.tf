variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type        = string
}

variable "department_name" {
  description = "Department folder name"
  type        = string
}

variable "script_key" {
  description = "Key of the script"
  type        = string
}

variable "short_identifier_prefix" {
  description = "Short project wide resource identifier prefix"
  type        = string
}

variable "glue_scripts_bucket_id" {
  description = "Id of bucket where glue jobs scripts are stored"
  type        = string
}

variable "glue_temp_storage_bucket_id" {
  description = "Id of temp glue job storage"
  type        = string
}

variable "refined_zone_bucket_id" {
  description = "Refined zone bucket id"
  type        = string
}

variable "helper_script_key" {
  description = "Helpers script key"
  type        = string
}

variable "cleaning_helper_script_key" {
  description = "Cleaning helpers script key"
  type        = string
}

variable "glue_crawler_excluded_blobs" {
  description = "A list of blobs to ignore when crawling the job"
  type        = list(string)
  default     = []
}

variable "catalog_database" {
  description = "Catalog data name"
  type        = string
}

variable "worksheet_resource" {
  description = "Object returned by module.repairs_fire_alarm_aov[0].worksheet_resources"
  type        = map(any)
}

variable "refined_zone_catalog_database_name" {
  description = "Refined zone catalog database name"
  type        = string
}

variable "dataset_name" {
  description = "Name of the data set"
  type        = string
}

variable "address_cleaning_script_key" {
  description = "Address cleaning script key"
  type        = string
}

variable "glue_role_arn" {
  default = "Glue Role ARN that the job will use to excecute"
  type    = string
}
