variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type        = string
}

variable "data_cleaning_script_name" {
  description = "Name of the data cleaning script file"
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

variable "helper_module_key" {
  description = "Helpers Python module S3 object key"
  type        = string
}

variable "glue_crawler_excluded_blobs" {
  description = "A list of blobs to ignore when crawling the job"
  type        = list(string)
  default     = []
}

variable "source_catalog_table" {
  description = "Name of the source table in the catalog"
  type        = string
}

variable "trigger_crawler_name" {
  description = "Name of the trigger which should trigger the data cleaning defined in this module"
  type        = string
}

variable "workflow_name" {
  description = "Name of the workflow to add all the triggers created here to"
  type        = string
}

variable "dataset_name" {
  description = "Name of the data set"
  type        = string
}

variable "address_cleaning_script_key" {
  description = "S3 key of the Address cleaning script in the glue scripts bucket"
  type        = string
}

variable "address_matching_script_key" {
  description = "S3 key of the Address matching script in the glue scripts bucket"
  type        = string
}

variable "addresses_api_data_catalog" {
  description = "Name of the data catalog holding the addresses API data"
  type        = string
}

variable "trusted_zone_bucket_id" {
  description = "Trusted zone bucket id"
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

variable "department" {
  description = "The department with all its properties"
  type = object({
    identifier                         = string
    glue_role_arn                      = string
    refined_zone_catalog_database_name = string
    raw_zone_catalog_database_name     = string
    tags                               = map(string)
    environment                        = string
    identifier_snake_case              = string
    glue_temp_bucket = object({
      bucket_id = string
    })
    glue_scripts_bucket = object({
      bucket_id = string
    })
  })
}

variable "spark_ui_output_storage_id" {
  description = "Id of S3 bucket containing Spark UI output logs"
  type        = string
}

variable "is_live_environment" {
  description = "A flag indicting if we are running in a live environment for setting up automation"
  type        = bool
}

variable "is_production_environment" {
  description = "A flag indicting if we are running in production for setting up automation"
  type        = bool
}