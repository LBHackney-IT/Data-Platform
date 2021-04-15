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

# General

variable "key_name" {
  description = "Key to access EC2 instances."
  type        = string
}

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

#variable "environment" {
#  description = "Environment e.g. Dev, Stg, Prod, Mgmt."
#  type        = string
#}

# Tags
variable "application" {
  description = "Name of the application."
  type        = string
}

variable "department" {
  description = "Name of the department responsible for the service."
  type        = string
}

variable "environment" {
  description = "Environment e.g. development, testing, staging, production."
  type        = string
}
