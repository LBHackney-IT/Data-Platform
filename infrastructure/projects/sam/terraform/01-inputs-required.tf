# AppStream Infrastructure
# AppStream Infrastructure - 10-network
variable "appstream_azs" {
  description = "A list of availability zones names or ids in the AppStream region."
  type        = list(string)
  default     = []
}

variable "appstream_cidr" {
  description = "The CIDR block for the AppStream VPC."
  type        = string
}

variable "appstream_private_subnets" {
  description = "A list of private subnets inside the AppStream VPC."
  type        = list(string)
}

variable "appstream_public_subnets" {
  description = "A list of public subnets inside the AppStream VPC."
  type        = list(string)
}

# Core Infrastructure
# Core Infrastructure - 10-network


variable "core_azs" {
  description = "A list of availability zones names or ids in the Core region."
  type        = list(string)
  default     = []
}

variable "core_cidr" {
  description = "The CIDR block for the Core VPC."
  type        = string
}

variable "core_private_subnets" {
  description = "A list of private subnets inside the Core VPC."
  type        = list(string)
}

variable "core_public_subnets" {
  description = "A list of public subnets inside the Core VPC."
  type        = list(string)
}


# Mandatory variables, that are provided by the GitHub Action CI/CD. The shouldn't be changed!
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

variable "environment" {
  description = "Enviroment e.g. Dev, Stg, Prod, Mgmt."
  type        = string
}

#General

variable "key_name" {
  description = "Key to access EC2 instances."
  type        = string
}

/* Mandatory variables, that should be override in the config/terraform/*.tfvars. Please feel free to add as you need!
 ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
 ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
 VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
 */
