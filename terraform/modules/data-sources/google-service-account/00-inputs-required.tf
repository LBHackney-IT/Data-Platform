variable "is_live_environment" {
  description = "A flag indicting if we are running in a live environment for setting up automation"
  type        = bool
}

variable "department_name" {
  type = string
}

variable "identifier_prefix" {
  type = string
}
