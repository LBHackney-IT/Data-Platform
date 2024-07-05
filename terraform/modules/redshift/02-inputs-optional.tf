variable "additional_iam_roles" {
  description = "Additional IAM roles to attach to the Redshift cluster"
  type        = list(string)
  default     = []
}

variable "preferred_maintenance_window" {
  description = "The weekly time range (in UTC) during which automated cluster maintenance can occur"
  type        = string
  default     = "sun:02:00-sun:03:00"
}
