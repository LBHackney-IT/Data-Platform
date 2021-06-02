variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "project" {
  description = "The project name."
  type        = string
}

variable "environment" {
  description = "Enviroment e.g. Dev, Stg, Prod, Mgmt."
  type        = string
}

variable "instance_name" {
  description = "Name of instance"
  type        = string
}

variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type        = string
}

variable "watched_bucket_name" {
  description = "Name of bucket which will be watched for new objects to convert"
  type        = string
}

variable "watched_bucket_kms_key_arn" {
  description = "KMS Key ARN for the watched bucket where new objects to convert are placed"
  type        = string
}

variable "aws_subnet_ids" {
  description = "Array of subnet IDs"
  type        = list(string)
}
