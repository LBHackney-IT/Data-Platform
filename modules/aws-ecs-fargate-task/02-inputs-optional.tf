variable "cloudwatch_rule_event_pattern" {
  description = "json encoded event pattern for the cloudwatch event rule"
  type        = string
  default     = null
}

variable "cloudwatch_rule_schedule_expression" {
  description = "Schedule to run the ECS task"
  type        = string
  default     = null
}