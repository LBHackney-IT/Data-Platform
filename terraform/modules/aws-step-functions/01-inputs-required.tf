
variable "name" {
  type        = string
  description = "name of the state machine"
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.name))
    error_message = "name must be alphanumeric, dashes and underscores are allowed"
  }
}

variable "definition" {
  type        = string
  description = "definition of the state machine"
}

variable "role_arn" {
  type        = string
  description = "role arn for the state machine"
}
