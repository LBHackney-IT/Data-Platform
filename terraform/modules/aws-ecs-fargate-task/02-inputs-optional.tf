variable "security_groups" {
  description = "Security groups the task should be attached to"
  type        = list(string)
  default     = []
}
