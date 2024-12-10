variable "glue_crawler_excluded_blobs" {
  description = "A list of blobs to ignore when crawling the job"
  type        = list(string)
  default     = []
}

variable "google_sheet_import_schedule" {
  description = "Cron schedule for importing the Google sheet using AWS Glue"
  type        = string
  default     = "cron(0 01 ? * 2-6 *)"
  validation {
    condition = can(regex(
      "^cron\\((\\d|[1-5]\\d)\\s(\\d|1\\d|2[0-3])\\s([1-9]|[12]\\d|3[01]|\\?|L|W)\\s([1-9]|1[0-2]|JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC|\\*)\\s([1-7]|SUN|MON|TUE|WED|THU|FRI|SAT|\\?|L|\\*)\\s(\\*|\\d{4})\\)$",
      var.google_sheet_import_schedule
      )) && length(regexall(
      "\\d{1,2}/\\d{1,2}",
      var.google_sheet_import_schedule
      )) == 0 && (length(regexall(
        "\\?",
        var.google_sheet_import_schedule
    )) <= 1 || !contains(split(" ", var.google_sheet_import_schedule), "?"))


    error_message = <<-EOT
      Invalid cron expression. The cron syntax must follow:
      cron(Minutes Hours Day-of-month Month Day-of-week Year)

      Minutes: 0-59 (use , - * /)
      Hours: 0-23 (use , - * /)
      Day-of-month: 1-31 (use , - * ? / L W)
      Month: 1-12 or JAN-DEC (use , - * /)
      Day-of-week: 1-7 or SUN-SAT (use , - * ? / L)
      Year: 1970-2199 (use , - * /)

      Additional rules:
      1. You cannot specify both Day-of-month and Day-of-week fields; use "?" in one.
      2. Cron rates faster than 5 minutes are not supported.
      EOT
  }
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

variable "create_workflow" {
  description = "Flag to indicate whether to create workflow"
  type        = bool
  default     = false
}

variable "max_retries" {
  description = "Maximum number of times to retry this job if it fails"
  type        = number
  default     = 2

  validation {
    condition     = var.max_retries >= 0 && var.max_retries <= 3
    error_message = "Maximum number of retries must be between 0 and 3."
  }
}
