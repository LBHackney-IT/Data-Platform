# This file and the following variables was added to stop a series of warnings being shown during plan and apply
# because the environment config files contain variables for multiple terraform modules.
# Blocks are defined for the unused (and therefore redundant) variables a provide defaults so that if they aren't
# provided at any point the module won't throw errors.
variable "transit_gateway_private_subnets" {
  default = false
}

variable "transit_gateway_availability_zones" {
  default = false
}

variable "transit_gateway_cidr" {
  default = false
}

variable "aws_mosaic_vpc_id" {
  default = false
}

variable "aws_housing_vpc_id" {
  default = false
}

variable "aws_mosaic_prod_account_id" {
  default = false
}

variable "aws_data_platform_account_id" {
  default = false
}

variable "aws_vpc_id" {
  default = false
}

variable "aws_dp_vpc_id" {
  default = false
}