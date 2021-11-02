variable "department" {
  description = "The department with all its properties"
  type = object({
    identifier    = string
    glue_role_arn = string
    tags          = map(string)
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

variable "glue_scripts_bucket_id" {
  description = "S3 bucket which contains the Glue scripts"
  type        = string

  validation {
    condition     = length(var.glue_scripts_bucket_id) > 7
    error_message = "The bucket ID variable must contain the name of the Glue scripts bucket."
  }
}
