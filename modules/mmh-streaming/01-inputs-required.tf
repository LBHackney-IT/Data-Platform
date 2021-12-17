variable "tags" {
  type = map(string)
}

variable "identifier_prefix" {
  type = string
}

variable "vpc_id" {
  description = "VPC ID to deploy the kafta instance into"
  type        = string
}

variable "subnet_ids" {
  type = list(string)
}
