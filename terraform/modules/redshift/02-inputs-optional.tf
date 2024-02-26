variable "additional_iam_roles" {
  description = "Additional IAM roles to attach to the Redshift cluster"
  type        = list(string)
  default     = []
}
