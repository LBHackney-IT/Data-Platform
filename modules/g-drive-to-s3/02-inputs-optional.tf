variable "workflow_names" {
  description = "A list workflow names to be triggered after import"
  type        = list(string)
  default     = []
}

variable "workflow_arns" {
  description = "A list of workflow arns to be triggered after import"
  type        = list(string)
  default     = []
}
