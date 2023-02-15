# Tags
variable "environment" {
  description = "Environment e.g. Dev, Stg, Prod, Mgmt."
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

variable "aws_dev_deploy_iam_role_name" {
  description = "AWS IAM role name to assume for deployment in development environment"
  type        = string
}

variable "aws_api_account_id" {
  description = "AWS api account id"
  type        = string
}

variable "aws_hackit_account_id" {
  description = "AWS hackit account id"
  type        = string
}

variable "google_project_id" {
  description = "The ID of the google project used as the target for resource deployment"
  type        = string
}

variable "qlik_server_instance_type" {
  description = "The instance type to use for the Qlik server"
  type        = string
}

variable "qlik_ssl_certificate_domain" {
  description = "The domain name associated with an existing AWS Certificate Manager certificate"
  type        = string
}

variable "redshift_public_ips" {
  description = "Public IP addresses for the redshift cluster"
  type        = list(string)
}

variable "redshift_port" {
  description = "Port that the redshift cluster is running on"
  type        = number
}

variable "emails_to_notify_with_budget_alerts" {
  description = "Array of emails or email groups who will be notified by the budget reporting"
  type        = list(string)
}

variable "datahub_url" {
  description = "Datahub URL"
  type        = string
}

variable "rentsense_target_path" {
  description = "The S3 path to target when copying rentsense data"
  type        = string
}
