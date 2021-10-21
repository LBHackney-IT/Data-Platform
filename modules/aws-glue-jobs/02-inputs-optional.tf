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
