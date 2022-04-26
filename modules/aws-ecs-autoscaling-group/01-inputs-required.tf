variable "name" {
  description = "Name of ECS autoscaling group"
  type        = string
}

variable "ecs_cluster_name" {
  description = "The ECS cluster name for the auto scaling policy"
  type        = string
}

variable "ecs_service_name" {
  description = "The ECS service name for the auto scaling policy"
  type        = string
}

variable "ecs_autoscaling_role_arn" {
  description = "IAM role with policy to handle autoscaling of ECS services"
  type        = string
}
