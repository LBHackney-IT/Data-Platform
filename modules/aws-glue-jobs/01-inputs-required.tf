variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "department" {
  description = "The department with all its properties"
  type        = object({
    department_identifier = string
    glue_role_arn         = string
  })
}

variable "job_name" {
  description = "Name of the AWS glue job"
  type        = string
}

variable "job_description" {
  description = "A description of the AWS glue job"
  type        = string
}

variable "script_name" {
  description = <<EOF
    Optional.
    Name of the Glue job script. If no value is provided,
    then it will be the same as the job name
  EOF
  type        = string
  default     = null
}

variable "glue_scripts_bucket_id" {
  description = "S3 bucket which contains the Glue scripts"
  type        = string
}
