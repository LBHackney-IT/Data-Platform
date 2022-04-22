variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "short_identifier_prefix" {
  type        = string
  description = "Project wide resource short identifier prefix"
}

variable "vpc_id" {
  description = "The ID of the VPC to set the server up in"
  type        = string
}

variable "vpc_subnet_ids" {
  description = "A list of VPC Subnet IDs the server could be deployed in"
  type        = list(string)
}

variable "ecs_cluster_arn" {
  type        = string
  description = "The ECS cluster ARN in which to run the task"
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

variable "load_balancer_properties" {
  description = "Properties of the load balancer to be attached to the ECS container"
  type = object({
    target_group_properties = list(object({
      arn  = string
      port = string
    }))
    security_group_id = string
  })
}

variable "is_live_environment" {
  description = "A flag indicting if we are running in a live environment for setting up automation"
  type        = bool
}
