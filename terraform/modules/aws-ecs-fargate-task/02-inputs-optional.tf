variable "security_groups" {
  description = "Security groups the task should be attached to"
  type        = list(string)
  default     = []
}

variable "enable_eventbridge_trigger" {
  description = "Whether EventBridge rules for the ECS tasks are enabled"
  type        = bool
  default     = true
}
