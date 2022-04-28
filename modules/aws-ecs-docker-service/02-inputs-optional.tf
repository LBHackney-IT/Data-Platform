variable "ssm_parameter_arns" {
  type        = list(string)
  default     = []
  description = "List of SSM parameter ARNs that the container should have access to"
}