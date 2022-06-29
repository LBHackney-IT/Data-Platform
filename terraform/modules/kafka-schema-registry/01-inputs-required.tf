variable "tags" {
  type = map(string)
}

variable "project" {
  description = "The project name."
  type        = string
}

variable "environment" {
  description = "Environment e.g. Dev, Stg, Prod, Mgmt."
  type        = string
}

variable "identifier_prefix" {
  type = string
}

variable "vpc_id" {
  description = "VPC ID to deploy the kafta instance into"
  type        = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "bootstrap_servers" {
  description = "One or more DNS names (or IP addresses) and port pairs."
  type        = string
}

variable "bastion_private_key_ssm_parameter_name" {
  description = "SSM paramater name where the bastion private key is stored"
  type        = string
}

variable "bastion_instance_id" {
  description = "Instance ID of the bastion"
  type        = string
}

variable "topics" {
  description = "List of kafka topics to manage schemas for"
  type        = list(string)
}

variable "is_live_environment" {
  description = "A flag indicting if we are running in a live environment for setting up automation"
  type        = bool
}