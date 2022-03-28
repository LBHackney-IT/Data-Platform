variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type        = string
}

variable "short_identifier_prefix" {
  description = "Project wide resource short identifier prefix"
  type        = string
}

variable "instance_type" {
  description = "The instance type to use for the Qlik server"
  type        = string
}

variable "ssl_certificate_domain" {
  description = "The domain name associated with an existing AWS Certificate Manager certificate"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC to set the server up in"
  type        = string
}

variable "vpc_subnet_ids" {
  description = "A list of VPC Subnet IDs the server could be deployed in"
  type        = list(string)
}

variable "environment" {
  description = "Environment e.g. dev, stg, prod, mgmt."
  type        = string
}

variable "aws_ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
}

variable "amazon_ssm_managed_instance_core_arn" {
  description = "EC2 IAM Policy ARN"
  type        = string
}