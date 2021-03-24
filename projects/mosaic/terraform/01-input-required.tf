# Core Infrastructure
# Core Infrastructure - 10-network
variable "core_azs" {
  description = "A list of availability zones names or ids in the Core region."
  type        = list(string)
  default     = []
}

variable "core_cidr" {
  description = "The CIDR block for the Core VPC."
  type        = string
}

variable "core_private_subnets" {
  description = "A list of private subnets inside the Core VPC."
  type        = list(string)
}

variable "core_public_subnets" {
  description = "A list of public subnets inside the Core VPC."
  type        = list(string)
}

variable "whitelist" {
  description = "List of allowed IPs for Bastion."
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
