variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}

variable "identifier_prefix" {
  type        = string
  description = "Environment identifier prefix"
  default     = ""
}