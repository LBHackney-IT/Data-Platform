# Core Infrastructure
# Core Infrastructure - 10-network
variable "core_azs" {
  description = "A list of availability zones names or ids in the core region."
  type        = list(string)
  default     = []
}

variable "core_cidr" {
  description = "The CIDR block for the core VPC."
  type        = string
}

variable "core_private_subnets" {
  description = "A list of private subnets inside the core VPC."
  type        = list(string)
}

# Tags
variable "application" {
  description = "Name of the application."
  type        = string
}

variable "department" {
  description = "Name of the department responsible for the service."
  type        = string
}

variable "environment" {
  description = "Environment e.g. development, testing, staging, production."
  type        = string
}
