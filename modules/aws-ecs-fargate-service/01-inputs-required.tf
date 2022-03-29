variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
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

variable "operation_name" {
  type        = string
  description = "A unique name for your task definition, ecs cluster and repository."
}

variable "ecs_cluster_arn" {
  type        = string
  description = "The ECS cluster ARN in which to run the task"
}

variable "environment_variables" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "A list of objects containing environment variables as key value pairs for the task's task definition."
}

variable "aws_subnet_ids" {
  description = "Array of subnet IDs"
  type        = list(string)
}
