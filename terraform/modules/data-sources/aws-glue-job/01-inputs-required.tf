variable "job_name" {
  description = "Name of the AWS glue job"
  type        = string

  validation {
    condition     = length(var.job_name) > 7
    error_message = "Job name must be at least 7 characters and include the department name."
  }
}