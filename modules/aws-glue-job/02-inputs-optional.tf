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

variable "script_name" {
  description = <<EOF
    Optional.
    Name of the Glue job script. If no value is provided,
    then it will be the same as the job name
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

variable "number_of_workers_for_glue_job" {
  description = "Specify the number of worker to use for the glue job"
  type        = number
  default     = 2

  validation {
    condition     = var.number_of_workers_for_glue_job >= 2 && var.number_of_workers_for_glue_job < 12
    error_message = "Number of workers should be greater than or equal to 2 and less than 12."
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

variable "glue_role_arn" {
  description = "Glue Role ARN that the job will use to execute"
  type        = string
  default     = null
}
