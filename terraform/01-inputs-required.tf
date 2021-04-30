# Mandatory variables, that are provided by the GitHub Action CI/CD. The shouldn't be changed!
variable "aws_deploy_region" {
  description = "AWS region to deploy to"
  type        = string
}

variable "aws_deploy_account" {
  description = "AWS account id to deploy to"
  type        = string
}

variable "aws_api_account" {
  description = "AWS api account id"
  type        = string
}

variable "aws_deploy_iam_role_name" {
  description = "AWS IAM role name to assume for deployment"
  type        = string
}

variable "environment" {
  description = "Enviroment e.g. Dev, Stg, Prod, Mgmt."
  type        = string
}

variable "google_project_id" {
  description = "Id of google project to which service accounts will be deployed to"
  type        = string
}

variable "assume_roles" {
  description = "Used to dynamically assume a role for staging and production deploys, while allowing assume role to be skipped in local terraform plan/apply."
  type        = list
}

variable "transit_gateway_cidr" {
  description = "The CIDR block for the transit gateway VPC."
  type        = string
}

/* Mandatory variables, that should be override in the config/terraform/*.tfvars. Please feel free to add as you need!
 ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
 ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
 VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
 */
