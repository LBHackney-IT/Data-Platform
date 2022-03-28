variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "project" {
  description = "The project name."
  type        = string
}

variable "environment" {
  description = "Enviroment e.g. dev, stg, prod, mgmt."
  type        = string
}

variable "bucket_name" {
  description = "S3 Bucket name"
  type        = string
}

variable "bucket_identifier" {
  description = "URL safe bucket identifier"
  type        = string
}

variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type        = string
}
