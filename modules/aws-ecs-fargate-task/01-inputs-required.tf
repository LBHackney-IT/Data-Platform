variable "operation_name" {
  type        = string
  description = "A unique name for your task definition, ecs cluster and repository."
}

variable "environment_variables" {
  type        = list(object({
    name = string
    value = string
  }))
  description = "A list of objects containing environment variables as key value pairs for the task's task definition."
}

variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "ecs_task_role_policy_document" {
  description = "Policy document to attach to the ECS task definition iam role"
  type = string
}
