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

variable "aws_subnet_ids" {
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

variable "vpc_id" {
  description = "The ID of the VPC to set the server up in"
  type        = string
}

variable "ecs_cluster_arn" {
  type        = string
  description = "The ECS cluster ARN in which to run the task"
}

variable "alb_id" {
  description = "ID of ALB in use"
  type        = string
}

variable "alb_target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}

variable "alb_security_group_id" {
  description = "Id of the ALB security group"
  type        = string
}

variable "ecr_repository_url" {
  description = "ECR Repo url"
  type        = string
}

variable "container_properties" {
  description = "Properties of the container to be deployed to ECS"
  type = object({
    container_name         = string
    image_name             = string
    port                   = number
    cpu                    = number
    memory                 = number
    load_balancer_required = bool
    environment_variables  = list(object({
      name  = string
      value = string
    }))
  })
}
