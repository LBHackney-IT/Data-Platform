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

variable "table_filter" {
  description = "Used to create unique resources we recreating JDBC connection for multiple tables based on list of filters"
  type        = string
  default     = null
}