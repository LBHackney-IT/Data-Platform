variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "job_name" {
  description = "Name of the AWS glue job"
  type        = string
}

variable "glue_role_arn" {
  description = "Glue Role ARN that the job will use to excecute"
  type        = string
}

variable "job_script_location" {
  description = "S3 URL of the location of the script for the glue job"
  type        = string
}

variable "job_arguments" {
  description = "Arguments to pass to the glue job"
  type        = map(string)
}

variable "name_prefix" {
  description = "Prefix to add to the name of the triggers and crawlers."
  type        = string
}

variable "database_name" {
  description = "Name of database"
  type        = string
}

variable "table_prefix" {
  description = "Prefix to give to tables that are crawled"
  type        = string
}

variable "s3_target_location" {
  description = "URL for where the target data will be stored in S3"
  type        = string
}
