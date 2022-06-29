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
  description = "The percentage CPU target value for ECS service"
  type        = number
  default     = 80
}

variable "memory_target_value" {
  description = "The percentage Memory target value for ECS service"
  type        = number
  default     = 80
}

variable "task_scale_in_cooldown_period" {
  description = "The amount of time, in seconds, after a scale in activity completes before another task scale in activity can start."
  type        = number
  default     = 60
}

variable "task_scale_out_cooldown_period" {
  description = "The amount of time, in seconds, after a scale out activity completes before another task scale out activity can start."
  type        = number
  default     = 60
}
