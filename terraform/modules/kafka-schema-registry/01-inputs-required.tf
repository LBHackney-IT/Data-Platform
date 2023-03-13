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

variable "datahub_gms_security_group_id" {
  description = "Security group id of Datahub GMS"
  type        = string
}

variable "datahub_mae_consumer_security_group_id" {
  description = "Security group id of Datahub MAE consumer"
  type        = string
}

variable "datahub_mce_consumer_security_group_id" {
  description = "Security group id of Datahub MCE consumer"
  type        = string
}

variable "kafka_security_group_id" {
  description = "Security group id of kafka"
  type        = string
}

variable "housing_intra_account_ingress_cidr" {
  description = "Cidr block for intra account ingress rules for housing"
  type        = list(string)
}

variable "schema_registry_alb_security_group_id" {
  description = "Security group id of schema registry ALB"
  type        = string
}

variable "kafka_tester_lambda_security_group_id" {
  description = "Security group id of the tester lambda"
  type        = string
}
