variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type        = string
}

variable "department" {
  description = "The department with all its properties"
  type = object({
    identifier                         = string
    identifier_snake_case              = string
    glue_role_arn                      = string
    refined_zone_catalog_database_name = string
    raw_zone_catalog_database_name     = string
    tags                               = map(string)
    environment                        = string
    glue_temp_bucket = object({
      bucket_id = string
    })
    glue_scripts_bucket = object({
      bucket_id = string
    })
  })
}

variable "script_name" {
  description = "Name of the script file"
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

variable "glue_temp_storage_bucket_url" {
  description = "Glue temp storage S3 bucket url"
  type        = string
}

variable "refined_zone_bucket_id" {
  description = "Refined zone bucket id"
  type        = string
}

variable "trusted_zone_bucket_id" {
  description = "Trusted zone bucket id"
  type        = string
}

variable "helper_module_key" {
  description = "Helpers Python module S3 object key"
  type        = string
}

variable "deequ_jar_file_path" {
  description = "Object key for Deequ jar"
  type        = string
}

variable "glue_crawler_excluded_blobs" {
  description = "A list of blobs to ignore when crawling the job"
  type        = list(string)
  default     = []
}

variable "worksheet_resource" {
  description = "Object returned by module.repairs_fire_alarm_aov[0].worksheet_resources"
  type        = map(any)
}

variable "dataset_name" {
  description = "Name of the data set"
  type        = string
}

variable "address_cleaning_script_key" {
  description = "Address cleaning script key"
  type        = string
}

variable "address_matching_script_key" {
  description = "Address matching script key"
  type        = string
}

variable "addresses_api_data_catalog" {
  description = "Name of the data catalog holding the addresses API data"
  type        = string
}

variable "glue_role_arn" {
  description = "Glue Role ARN that the job will use to excecute"
  type        = string
}

variable "match_to_property_shell" {
  description = "Set a strategy for address matching, excluding or including property shells"
  type        = string
  default     = ""
}

variable "pydeequ_zip_key" {
  description = "Pydeequ module to be used in Glue scripts"
  type        = string
}

variable "spark_ui_output_storage_id" {
  description = "Id of S3 bucket containing Spark UI output logs"
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
