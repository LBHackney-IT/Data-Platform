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
}

variable "glue_scripts_bucket_id" {
  description = "S3 bucket which contains the Glue scripts"
  type        = string
}
