variable "header_row_number" {
  description = "Header row number (0-indexed)"
  type        = number
  default     = 0
}

variable "glue_role_arn" {
  description = "Role to use for Glue jobs"
  type        = string
  default     = null
}
