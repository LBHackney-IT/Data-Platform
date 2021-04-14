# AppStream Infrastructure
# AppStream Infrastructure - 10-network
variable "appstream_create_igw" {
  description = "Controls if an Internet Gateway is created for public subnets and the related routes that connect them."
  type        = bool
  default     = true
}

variable "appstream_enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC."
  type        = bool
  default     = false
}

variable "appstream_enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC."
  type        = bool
  default     = true
}

variable "appstream_enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways for each of your private networks."
  type        = bool
  default     = false
}

variable "appstream_region" {
  description = "The AWS region the resources will be deployed into."
  type        = string
  default     = "eu-west-1"
}

variable "appstream_single_nat_gateway" {
  description = "Should be true if you want to provision a single shared NAT Gateway across all of your private networks."
  type        = bool
  default     = false
}

variable "appstream_security_group_egress" {
  description = "List of maps of egress rules to set on the AppStream VPC Security Group."
  type        = list(map(string))
  default     = null
}

variable "appstream_security_group_ingress" {
  description = "List of maps of ingress rules to set on the AppStream VPC Security Group."
  type        = list(map(string))
  default     = null
}

# Core Infrastructure
# Core Infrastructure - 10-network
variable "core_create_igw" {
  description = "Controls if an Internet Gateway is created for public subnets and the related routes that connect them."
  type        = bool
  default     = true
}

variable "core_enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC."
  type        = bool
  default     = false
}

variable "core_enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC."
  type        = bool
  default     = true
}

variable "core_enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways for each of your private networks."
  type        = bool
  default     = false
}

variable "core_region" {
  description = "The AWS region the resources will be deployed into."
  type        = string
  default     = "eu-west-2"
}

variable "core_single_nat_gateway" {
  description = "Should be true if you want to provision a single shared NAT Gateway across all of your private networks."
  type        = bool
  default     = false
}

variable "core_security_group_egress" {
  description = "List of maps of egress rules to set on the core VPC Security Group."
  type        = list(map(string))
  default     = null
}

variable "core_security_group_ingress" {
  description = "List of maps of ingress rules to set on the core VPC Security Group."
  type        = list(map(string))
  default     = null
}

# Core Infrastructure - 20-Sequel-Proval
variable "sequel_proval_instance_ami" {
  description = "Sequel Proval EC2 AMI ID."
  type        = string
  default     = "ami-0d0ff6df453a81e02"

}

variable "sequel_proval_instance_number" {
  description = "Sequel Proval EC2 instance count."
  type        = string
  default     = "1"
}

variable "sequel_proval_instance_type" {
  description = "Sequel Proval EC2 size."
  type        = string
  default     = "c4.xlarge"
}


# General
variable "profile" {
  description = "The AWS profile used to authenticate."
  type        = string
  default     = "default"
}

# Tags
variable "automation_build_url" {
  description = "The project automation build url."
  type        = string
  default     = "unknown"
}

variable "confidentiality" {
  description = "The project confidentiality status"
  type        = string
  default     = "Internal"
}

variable "custom_tags" {
  description = "Map of custom tags (merged and added to existing other Tags). Must not overlap with any already defined tags."
  type        = map(string)
  default     = {}
}

variable "phase" {
  description = "The project phase."
  type        = string
  default     = "default"
}

variable "project" {
  description = "The project name."
  type        = string
  default     = "internal"
}

variable "stack" {
  description = "The project stack."
  type        = string
  default     = "standalone"
}

variable "team" {
  description = "Name of the team responsible for the service."
  type        = string
  default     = "cloud_deployment"
}
