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
  default     = true
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
  description = "List of maps of egress rules to set on the Core VPC Security Group."
  type        = list(map(string))
  default     = null
}

variable "core_security_group_ingress" {
  description = "List of maps of ingress rules to set on the Core VPC Security Group."
  type        = list(map(string))
  default     = null
}

# VPC peering
variable "production_api_vpc_cidrs" {
  description = "The CIDR of the Production APIs VPC for Cross Account DMS."
  type        = list(string)
  default     = null
}

# Platform and Service API
variable "platform_api_id" {
  description = "The API ID of the Residents Social Care Platform API."
  type        = string
  default     = ""
}

variable "platform_api_key_id" {
  description = "The API key ID for the Residents Social Care Platform API."
  type        = string
  default     = ""
}

variable "service_api_show_historic_data_feature_flag" {
  description = "Show historic data feature flag for Social Care Case Viewer API."
  type        = string
  default     = "false"
}

# Core Infrastructure - 30-bastion
variable "bastion_instance_ami" {
  description = "Bastion EC2 AMI ID."
  type        = string
  default     = "ami-0e80a462ede03e653"
}

variable "bastion_instance_number" {
  description = "Bastion EC2 instance count."
  type        = string
  default     = "1"
}

variable "bastion_instance_type" {
  description = "Bastion EC2 size."
  type        = string
  default     = "t3.medium"
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
  default     = "internal"
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
  default     = "cloud-deployment"
}
