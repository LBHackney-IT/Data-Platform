# Tags
variable "environment" {
  description = "Environment e.g. Dev, Stg, Prod, Mgmt."
  type        = string
}

# Project Variables
variable "aws_deploy_region" {
  description = "AWS region to deploy to"
  type        = string
}

variable "aws_deploy_account" {
  description = "AWS account id to deploy to"
  type        = string
}

variable "aws_deploy_iam_role_name" {
  description = "AWS IAM role name to assume for deployment"
  type        = string
}

variable "aws_api_account" {
  description = "AWS api account id"
  type        = string
}

variable "aws_hackit_account_id" {
  description = "AWS hackit account id"
  type        = string
}

variable "aws_vpc_id" {
  description = "The ID of the AWS VPC"
  type        = string
}

variable "google_project_id" {
  description = "The ID of the google project used as the target for resource deployment"
  type        = string
}

variable "qlik_server_instance_type" {
  description = "The instance type to use for the Qlik server"
  type        = string
}