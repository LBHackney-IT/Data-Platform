# Tags
variable "environment" {
  description = "Environment e.g. development, testing, staging, production."
  type        = string
}

# Project Variables
variable "aws_deploy_region" {
  description = "AWS region to deploy to"
  type        = string
}

variable "aws_deploy_account_id" {
  description = "AWS account id to deploy to"
  type        = string
}

variable "aws_deploy_iam_role_name" {
  description = "AWS IAM role name to assume for deployment"
  type        = string
}

variable "transit_gateway_availability_zones" {
  description = "A list of availability zones names or ids in the core region."
  type        = list(string)
}

variable "transit_gateway_cidr" {
  description = "The CIDR block for the VPC to attach to the Transit Gateway"
  type        = string
}

variable "secondary_transit_gateway_cidr" {
  description = "The secondary CIDR blocks for the VPC to attach to the Transit Gateway"
  type        = list(string)
}

variable "transit_gateway_private_subnets" {
  description = "A list of private subnets to attach to the VPC and route traffic to the Transit Gateway"
  type        = list(string)
}

variable "aws_mosaic_prod_account_id" {
  description = "AWS Mosaic Prod account ID"
  type        = string
}

variable "aws_api_vpc_id" {
  description = "Staging APIs peer VPC ID"
  type        = string
}

variable "aws_housing_vpc_id" {
  description = "Housing peer VPC ID"
  type        = string
}

variable "aws_mosaic_vpc_id" {
  description = "Mosaic peer VPC ID"
  type        = string
}

variable "aws_dp_vpc_id" {
  description = "Data Platform VPC ID"
  type        = string
}

variable "aws_data_platform_account_id" {
  description = "Data Platform account ID"
  type        = string
}
