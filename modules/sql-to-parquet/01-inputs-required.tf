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
  description = "Nme of instance"
  type = string
}

variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type = string
}

variable "watched_bucket_name" {
  description = "Name of bucket which will be watched for new objects to convert"
  type = string
}

variable "aws_caller_identity" {
  description = "FIX ME"
  type = string
}
