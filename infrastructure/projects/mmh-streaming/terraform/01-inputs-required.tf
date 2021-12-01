variable "aws_deploy_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "eu-west-2"

}

variable "aws_deploy_account" {
  description = "AWS account id to deploy to"
  type        = string
}

variable "aws_deploy_iam_role_name" {
  description = "AWS account id to deploy to"
  type        = string
}

variable "core_region" {
  description = "region to deploy to"
  type        = string
}

variable "core_cidr" {
  type = string
}

variable "core_azs" {
  type = list(string)
}

variable "core_cidr_blocks" {
  type = list(string)
}

variable "application" {
  type = string
}

variable "department" {
  type = string
}

variable "environment" {
  type = string
}