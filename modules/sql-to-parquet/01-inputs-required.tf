variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "project" {
  description = "The project name."
  type        = string
}

variable "environment" {
  description = "Enviroment e.g. Dev, Stg, Prod, Mgmt."
  type        = string
}

variable "instance_name" {
  description = "nNme of instance"
  type = string
}

variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type = string
}
