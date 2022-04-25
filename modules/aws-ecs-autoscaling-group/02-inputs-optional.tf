variable "autoscaling_max_capacity" {
  description = "The max capacity of the ECS service target."
  type        = number
  default     = 100
}

variable "autoscaling_min_capacity" {
  description = "The min capacity of the ECS service target"
  type        = number
  default     = 1
}

variable "cpu_target_value" {
  description = "CPU target value for ECS service"
  type        = number
  default     = 80
}

variable "memory_target_value" {
  description = "Memory target value for ECS service"
  type        = number
  default     = 80
}
