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

variable "bucket_name" {
  description = "S3 Bucket name"
  type = string
}

variable "bucket_identifier" {
  description = "URL safe bucket identifier"
  type = string
}

variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type = string
}

variable "account_configuration" {
  description = "AWS account configuration"
  type = map(object({
    account_to_share_data_with = string,
    iam_role_name = string,
    s3_read_write_directory = string,
    s3_read_directories = list(string)
  }))
}


