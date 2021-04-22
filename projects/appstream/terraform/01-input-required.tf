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

variable "appstream_subnets" {
  description = "Appstream application subnets inside the AppStream VPC."
  type        = map(map(any))
}

variable "appstream_tgw_subnets" {
  description = "A list of private subnets inside the AppStream VPC used for Transit Gateway connection."
  type        = list(string)
}

# General
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
