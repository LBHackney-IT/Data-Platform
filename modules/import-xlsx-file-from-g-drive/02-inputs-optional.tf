variable "xlsx_import_schedule" {
  description = "Cron schedule for importing the Google sheet using AWS Glue"
  type        = string
  default     = "cron(0 01 ? * 2-6 *)"
}

variable "enable_glue_trigger" {
  description = "Enable AWS glue trigger"
  type        = string
  default     = false
}


variable "header_row_number" {
  description = "Header row number (0-indexed)"
  type        = number
  default     = 0
}

variable "tags" {
  description = "AWS tags"
  type        = map(string)
  default     = null
}
