variable "glue_job_names" {
  description = "A list glue jobs to be triggered after import"
  type        = list(string)
  default     = []
}

variable "job_arns" {
  description = "A list glue jobs to be triggered after import"
  type        = list(string)
  default     = []
}
