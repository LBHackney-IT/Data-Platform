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

variable "workflow_name" {
  description = "Optional. Workflow to add the triggers to."
  type        = string
  default     = null
}

variable "crawler_to_trigger" {
  description = <<EOF
    Must populate either this vairable or the job_to_trigger variable.
    The job and crawler created in this module will be triggered on completion of either
    the crawler given here or the job given in job_to_trigger.
  EOF
  type        = string
  default     = null
}

variable "job_to_trigger" {
  description = <<EOF
    Must populate either this vairable or the crawler_to_trigger variable.
    The job and crawler created in this module will be triggered on completion of either
    the job given here or the crawler given in crawler_to_trigger.
  EOF
  type        = string
  default     = null
}
