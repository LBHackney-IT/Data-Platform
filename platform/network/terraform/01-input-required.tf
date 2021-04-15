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

# Shared Services Infrastructure
# Shared Services Infrastructure - 10-network
variable "ss_primary_azs" {
  description = "A list of availability zones names or ids in the shared services region."
  type        = list(string)
  default     = []
}

variable "ss_primary_cidr" {
  description = "The CIDR block for the shared services VPC."
  type        = string
}

variable "ss_primary_mgmt_subnets" {
  description = "A list of management subnets inside the shared services VPC."
  type        = list(string)
}

variable "ss_primary_private_subnets" {
  description = "A list of private subnets inside the shared services VPC."
  type        = list(string)
}

variable "ss_primary_public_subnets" {
  description = "A list of public subnets inside the shared services VPC."
  type        = list(string)
}

variable "ss_primary_tgwattach_subnets" {
  description = "A list of tgw attach subnets inside the shared services VPC."
  type        = list(string)
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


# Palo Alto
variable "SSHLocation" {
  description = "SSH location IP ranges for Management interface."
  type        = list(string)
}

variable "key_name" {
  description = "Key to access PA instances."
  type        = string
}


