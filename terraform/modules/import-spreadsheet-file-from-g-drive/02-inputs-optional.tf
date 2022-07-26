variable "spreadsheet_import_schedule" {
  description = "Cron schedule for importing the Google sheet using AWS Glue"
  type        = string
  default     = "cron(0 01 ? * 2-6 *)"
}

variable "enable_glue_trigger" {
  description = "Enable AWS glue trigger"
  type        = string
  default     = false
}

variable "worksheets" {
  type = map(
    object({
      header_row_number = number
      worksheet_name    = string
    })
  )
  default = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "1"
    }
  }
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

variable "glue_role_arn" {
  description = "Role to use for Glue jobs"
  type        = string
  default     = null
}

variable "ingestion_schedule" {
  description = "cron expression that describes when the spreadsheet should be ingested onto the platform"
  type        = string
  default     = "cron(0 6 * * ? *)"
}

variable "enable_bookmarking" {
  description = "Enable glue job bookmarking"
  type        = bool
  default     = false
}
