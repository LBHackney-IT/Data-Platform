variable "tags" {
  description = "AWS tags"
  type        = map(string)
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

variable "alb_target_group_arns" {
  description = "ARN of the ALB target group"
  type = list(object({
    arn  = string
    port = string
  }))
}

variable "alb_security_group_id" {
  description = "Id of the ALB security group"
  type        = string
}

variable "cloudwatch_log_group_name" {
  description = "Name of the log group to export docker logs to"
  type        = string
}

variable "container_properties" {
  description = "Properties of the container to be deployed to ECS"
  type = object({
    container_name          = string
    image_name              = string
    image_tag               = string
    port                    = number
    cpu                     = number
    memory                  = number
    load_balancer_required  = bool
    standalone_onetime_task = bool
    port_mappings = list(object({
      containerPort = number
      hostPort      = number
    }))
    environment_variables = list(object({
      name  = string
      value = string
    }))
    mount_points = list(object({
      sourceVolume  = string
      containerPath = string
      readOnly      = bool
    }))
    volumes = list(string)
  })
}
