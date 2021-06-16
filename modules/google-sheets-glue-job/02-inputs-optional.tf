variable "google_sheet_import_schedule" {
  description = "Cron schedule for importing the Google sheet using AWS Glue"
  type        = string
  default     = "cron(0 23 ? * 1-5 *)"
}

variable "google_sheet_header_row_number" {
  description = "The Row Number that headers will be extracted from. Starts and defaults to 1"
  type        = number
  default     = 1
}

variable "enable_glue_trigger" {
  description = "Enable AWS glue trigger"
  type        = string
  default     = true
}

