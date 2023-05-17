variable "operation_name" {
  type        = string
  description = "A unique name for your task definition, ecs cluster and repository."
}

variable "ecs_cluster_arn" {
  type        = string
  description = "The ECS cluster ARN in which to run the task"
}

variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "ecs_task_role_policy_document" {
  description = "Policy document to attach to the ECS task definition iam role"
  type        = string
}

variable "aws_subnet_ids" {
  description = "Array of subnet IDs"
  type        = list(string)
}

variable "tasks" {
  description = "An array of objects containing tasks to be created"
  type = list(object({
    task_prefix                         = string
    cloudwatch_rule_schedule_expression = string
    cloudwatch_rule_event_pattern       = string
    task_cpu                            = number
    task_memory                         = number
    environment_variables = list(object({
      name  = string
      value = string
    }))
  }))
}
