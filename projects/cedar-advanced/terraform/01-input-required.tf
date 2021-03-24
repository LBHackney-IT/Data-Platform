# AppStream Infrastructure
# AppStream Infrastructure - 10-network
variable "appstream_azs" {
  description = "A list of availability zones names or ids in the AppStream region."
  type        = list(string)
  default     = []
}

variable "appstream_cidr" {
  description = "The CIDR block for the AppStream VPC."
  type        = string
}

variable "appstream_private_subnets" {
  description = "A list of private subnets inside the AppStream VPC."
  type        = list(string)
}

variable "appstream_public_subnets" {
  description = "A list of public subnets inside the AppStream VPC."
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
