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

variable "short_identifier_prefix" {
  description = "Short project wide resource identifier prefix"
  type        = string
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

variable "s3_bucket_to_write_to" {
  type = object({
    bucket_id   = string
    kms_key_arn = string
    kms_key_id  = string
    bucket_arn  = string
  })
}

variable "bastion_instance_id" {
  description = "Instance ID of the bastion"
  type        = string
}

variable "bastion_private_key_ssm_parameter_name" {
  description = "SSM paramater name where the bastion private key is stored"
  type        = string
}

variable "is_live_environment" {
  description = "A flag indicting if we are running in a live environment for setting up automation"
  type        = bool
}