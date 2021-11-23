variable "department" {
  description = "The department with all its properties"
  type = object({
    identifier            = string
    glue_role_arn         = string
    identifier_snake_case = string
    tags                  = map(string)
    environment           = string
    glue_temp_bucket = object({
      bucket_id = string
    })
    glue_scripts_bucket = object({
      bucket_id = string
    })
  })
}

variable "job_name" {
  description = "Name of the AWS glue job"
  type        = string

  validation {
    condition     = length(var.job_name) > 7
    error_message = "Job name must be at least 7 characters and include the department name."
  }
}

variable "helper_module_key" {
  description = "Helpers Python module S3 object key"
  type        = string
}

variable "pydeequ_zip_key" {
  description = "Pydeequ module to be used in Glue scripts"
  type        = string
}