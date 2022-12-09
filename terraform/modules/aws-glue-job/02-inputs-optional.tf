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

variable "glue_crawler_excluded_blobs" {
  description = "A list of blobs to ignore when crawling the job"
  type        = list(string)
  default = [
    "*.json",
    "*.txt",
    "*.zip",
    "*.xlsx"
  ]
}

variable "job_description" {
  description = "A description of the AWS glue job"
  type        = string
  default     = null
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

variable "job_parameters" {
  description = "Optional. Parameters to add to the Glue job"
  type        = map(string)
  default     = null
}

variable "workflow_name" {
  description = "Optional. Workflow to add the triggers to."
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

variable "number_of_workers_for_glue_job" {
  description = "Specify the number of worker to use for the glue job"
  type        = number
  default     = 2

  validation {
    condition     = var.number_of_workers_for_glue_job >= 2 && var.number_of_workers_for_glue_job <= 16
    error_message = "Number of workers should be greater than or equal to 2 and less than or equal to 16."
  }
}

variable "glue_job_worker_type" {
  description = "Specify the worker type to use for the glue job"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "G.1X", "G.2X"], var.glue_job_worker_type)
    error_message = "Worker type must be \"Standard\", \"G.1X\" or \"G.2X\"."
  }
}

variable "max_concurrent_runs_of_glue_job" {
  description = "Specify the max number of concurrent runs for the glue job"
  type        = number
  default     = 1

  validation {
    condition     = var.max_concurrent_runs_of_glue_job > 0
    error_message = "Maximum number of concurrent runs for this job must be greater than 0."
  }
}

variable "trigger_enabled" {
  description = "Set to false to disable scheduled or conditional triggers for the glue job"
  type        = bool
  default     = true
}

variable "extra_jars" {
  description = "S3 path for extra jars to be used in Glue jobs"
  type        = list(string)
  default     = []
}

variable "glue_job_timeout" {
  description = "Set the timeout for the glue job in minutes. By default this is set to 120"
  type        = number
  default     = 120
}

variable "glue_role_arn" {
  description = "Glue Role ARN that the job will use to execute. Must be populated if department is not provided."
  type        = string
  default     = null
}


variable "glue_scripts_bucket_id" {
  description = "Bucket ID where the glue scripts are saved. Must be populated if department is not provided."
  type        = string
  default     = null
}

variable "glue_temp_bucket_id" {
  description = "Bucket ID for glue temporary storage. Must be populated if department is not provided."
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment e.g. Dev, Stg, Prod. Must be populated if department is not provided."
  type        = string
  default     = null
}

variable "tags" {
  description = "AWS tags. Must be populated if department is not provided."
  type        = map(string)
  default     = null
}

variable "jdbc_connections" {
  description = "A list of JDBC connections to use in Glue job"
  type        = list(string)
  default     = null
}

variable "glue_version" {
  description = "Version of glue to use, defaulted to 2.0"
  type        = string
  default     = "2.0"
  validation {
    condition     = contains(["1.0", "2.0", "3.0", "4.0"], var.glue_version)
    error_message = "Glue version supplied is not valid, must be \"1.0\", \"2.0\", \"3.0\" or \"4.0\"."
  }
}
