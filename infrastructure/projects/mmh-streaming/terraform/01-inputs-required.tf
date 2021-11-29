variable "aws_deploy_region" {
  description = "AWS region to deploy to"
  type        = string
}

variable "core_cidr" {
  type = string
}

variable "core_azs" {
  type = list(any)
}

variable "core_cidr_blocks" {
  type    = list(any)
}

variable "application" {
  type    = string
}

variable "department" {
  type    = string
}

variable "environment" {
  type    = string
}