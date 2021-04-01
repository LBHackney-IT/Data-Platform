variable "google_sheet_import_schedule" {
  description = "Cron schedule for importing the Google sheet using AWS Glue"
  type        = string
  default     = "cron(0 23 ? * 1-5 *)"
}
