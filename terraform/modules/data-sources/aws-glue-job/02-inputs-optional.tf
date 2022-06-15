variable "department" {
  description = "The department with all its properties."
  default     = null
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

variable "script_name" {
  description = <<EOF
    Name of the Glue job script file.
    Must match the name of file holding the glue script in this repository
    This is required if the script isn't already saved in S3.
  EOF
  type        = string
  default     = null
}

variable "script_s3_object_key" {
  description = <<EOF
    The S3 object key for the glue job script.
    If the script is not saved in S3 then leave this blank.
  EOF
  type        = string
  default     = null
}

variable "triggered_by_crawler" {
  description = <<EOF
    Can populate either this variable, the job_to_trigger variable or the schedule.
    The job created in this module will be triggered on completion of either
    the crawler given here or the job given in job_to_trigger or the schedule.
  EOF
  type        = string
  default     = null
}

variable "triggered_by_job" {
  description = <<EOF
    Can populate either this variable, the crawler_to_trigger variable or the schedule.
    The job created in this module will be triggered on completion of either
    the job given here or the crawler given in crawler_to_trigger.
  EOF
  type        = string
  default     = null
}

variable "schedule" {
  description = <<EOF
    Can populate either this variable, job_to_trigger or the crawler_to_trigger.
    Schedule to run the Glue job
  EOF
  type        = string
  default     = null
}

variable "crawler_details" {
  description = "Inputs required to create a crawler"
  type = object({
    database_name      = string
    s3_target_location = string
    table_prefix       = optional(string)
    configuration      = optional(string)
  })
  default = {
    database_name      = null
    s3_target_location = null
  }
}


variable "glue_scripts_bucket_id" {
  description = "Bucket ID where the glue scripts are saved. Must be populated if department is not provided."
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment e.g. Dev, Stg, Prod. Must be populated if department is not provided."
  type        = string
  default     = null
}