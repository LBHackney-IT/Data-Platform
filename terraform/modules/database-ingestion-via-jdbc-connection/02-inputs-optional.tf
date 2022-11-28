variable "schema_name" {
  description = "Name of schema in the database containing tables to be ingested"
  type        = string
  default     = null
}

variable "create_workflow" {
  description = "Used to determine whether a workflow should be created for the ingestion process"
  type        = bool
  default     = true
}

variable "job_schedule" {
  description = "Used to set the schedule for the ingestion job"
  type        = string
  default     = "cron(15 0 ? * MON,TUE,WED,THU,FRI *)"
}
