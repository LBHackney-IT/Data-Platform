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

variable "job_parameters" {
  description = "Optional. Parameters to add to the Glue job"
  type        = map(string)
  default     = null
}

variable "script_name" {
  description = <<EOF
    Optional.
    Name of the Glue job script. If no value provided,
    then this will be worked out from the job name
  EOF
  type        = string
  default     = null
}

variable "workflow_name" {
  description = "Optional. Workflow to add the triggers to."
  type        = string
  default     = null
}

variable "trigger_name" {
  description = "Optional. Trigger to run the Glue job"
  type        = string
  default     = null
}

variable "crawler_to_trigger" {
  description = <<EOF
    Must populate either this variable or the job_to_trigger variable.
    The job created in this module will be triggered on completion of either
    the crawler given here or the job given in job_to_trigger.
  EOF
  type        = string
  default     = null
}

variable "job_to_trigger" {
  description = <<EOF
    Must populate either this variable or the crawler_to_trigger variable.
    The job created in this module will be triggered on completion of either
    the job given here or the crawler given in crawler_to_trigger.
  EOF
  type        = string
  default     = null
}

variable "schedule" {
  description = "Optional. Schedule to run the Glue jobs"
  type        = string
  default     = "ON_DEMAND"
}

variable "job_arguments" {
  description = "Arguments to pass to the glue job"
  type        = map(string)
}