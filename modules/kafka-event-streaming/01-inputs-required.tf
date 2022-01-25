variable "tags" {
  type = map(string)
}

variable "project" {
  description = "The project name."
  type        = string
}

variable "environment" {
  description = "Environment e.g. Dev, Stg, Prod, Mgmt."
  type        = string
}

variable "identifier_prefix" {
  type = string
}

variable "vpc_id" {
  description = "VPC ID to deploy the kafta instance into"
  type        = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "role_arns_to_share_access_with" {
  description = ""
}

variable "cross_account_lambda_roles" {
  type        = list(string)
  description = "Role ARNs of Lambda functions in other accounts that need to access the glue schema registry"
}

variable "bucket_name" {
  type = string
  description = "Name of the bucket where events will be saved"
}

variable "bucket_arn" {
  type = string
  description = "ARN of the bukcet where events will be saved"
}

variable "kms_key_id" {
  type = string
  description = "KMS key ID for the bucket where events will be saved"
}

variable "kms_key_arn" {
  type = string
  description = "KMS key ARN for the bucket where events will be saved"
}
