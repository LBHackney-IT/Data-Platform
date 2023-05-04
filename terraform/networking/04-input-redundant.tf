# This file and the following variables was added to stop a series of warnings being shown during plan and apply
# because the environment config files contain variables for multiple terraform modules.
# Blocks are defined for the unused (and therefore redundant) variables a provide defaults so that if they aren't
# provided at any point the module won't throw errors.
variable "redshift_public_ips" {
  default = false
}

variable "redshift_port" {
  default = false
}

variable "email_to_notify" {
  default = false
}

variable "aws_vpc_id" {
  default = false
}

variable "academy_production_database_username" {
  default = false
}

variable "academy_production_database_password" {
  default = false
}

variable "copy_liberator_to_pre_prod_lambda_execution_role" {
  default = false
}

variable "pre_production_liberator_data_storage_kms_key_arn" {
  default = false
}