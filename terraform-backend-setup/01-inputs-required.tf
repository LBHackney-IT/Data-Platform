# Mandatory variables, that are provided by the GitHub Action CI/CD. The shouldn't be changed!
//variable "aws_deploy_region" {
//  description = "AWS region to deploy to"
//  type        = string
//}
//
//variable "aws_deploy_account" {
//  description = "AWS account id to deploy to"
//  type        = string
//}
//
//variable "aws_deploy_iam_role_name" {
//  description = "AWS IAM role name to assume for deployment"
//  type        = string
//}

variable "environment" {
  description = "Enviroment e.g. Dev, Stg, Prod, Mgmt."
  type        = string
}

/* Mandatory variables, that should be override in the config/terraform/*.tfvars. Please feel free to add as you need!
 ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
 ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
 VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
 */