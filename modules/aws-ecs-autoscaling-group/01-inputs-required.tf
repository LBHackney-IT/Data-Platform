variable "name" {
  description = "Name of ECS autoscaling group"
  type        = string
}

variable "ecs_cluster_name" {
  type        = string
  description = "The ECS cluster name for the auto scaling policy"
}

variable "ecs_service_name" {
  type        = string
  description = "The ECS service name for the auto scaling policy"
}

variable "ecs_autoscaling_role_arn" {
  description = "IAM role with policy to handle autoscaling of ECS services"
}
