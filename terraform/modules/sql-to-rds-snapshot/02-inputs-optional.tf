variable "enable_eventbridge_trigger" {
  description = "Whether the S3 EventBridge trigger for the snapshot ECS task is enabled"
  type        = bool
  default     = true
}
