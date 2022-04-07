variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type        = string
}

variable "development_endpoint_role_arn" {
  description = "The role provided controls acces to data from the notebook."
  type        = string
}

variable "instance_name" {
  description = "Name of the notebook instance, typically set to the department name"
  type        = string
}