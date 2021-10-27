variable "glue_crawler_excluded_blobs" {
  description = "A list of blobs to ignore when crawling the job"
  type        = list(string)
  default     = []
}

variable "google_sheet_import_schedule" {
  description = "Cron schedule for importing the Google sheet using AWS Glue"
  type        = string
  default     = "cron(0 01 ? * 2-6 *)"
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
variable "sheets_credentials_name" {
  description = "Override the default department Google sheets credentials name"
  type        = string
  default     = null
}

