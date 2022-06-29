variable "role_arns_to_share_access_with" {
  description = "A list of role arns to enable cross account access"
  type        = list(string)
  default     = []
}
