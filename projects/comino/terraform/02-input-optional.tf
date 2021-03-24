# Core Infrastructure

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

# Core Infrastructure - 20-rb - Revenues and Benefit (rb) APP - Microsoft Windows Server 2019 Base
variable "rb_app_instance_ami" {
  description = "Revenues and Benefit APP Windows AMI ID."
  type        = string
  default     = "ami-08698c6c1186276cc"
}

variable "rb_app_instance_number" {
  description = "Revenues and Benefit APP Windows instance count."
  type        = string
  default     = "1"
}

variable "rb_app_instance_type" {
  description = "Revenues and Benefit APP Windows size."
  type        = string
  default     = "t3.xlarge"
}

# Core Infrastructure - 25-sc - Social Care (sc) APP - Microsoft Windows Server 2019 Base
variable "sc_app_instance_ami" {
  description = "Social Care APP Windows AMI ID."
  type        = string
  default     = "ami-08698c6c1186276cc"
}

variable "sc_app_instance_number" {
  description = "Social Care APP Windows instance count."
  type        = string
  default     = "1"
}

variable "sc_app_instance_type" {
  description = "Social Care APP Windows size."
  type        = string
  default     = "t3.xlarge"
}

# Core Infrastructure - 30-uh - Universal Housing (uh) APP - Microsoft Windows Server 2012 R2 Base
variable "uh_app_instance_ami" {
  description = "Universal Housing APP Windows AMI ID."
  type        = string
  default     = "ami-016250cb9ae5e5987"
}

variable "uh_app_instance_number" {
  description = "Universal Housing APP Windows instance count."
  type        = string
  default     = "1"
}

variable "uh_app_instance_type" {
  description = "Universal Housing APP Windows size."
  type        = string
  default     = "t3.large"
}

# Core Infrastructure - Database Server - Microsoft Windows Server 2019 with SQL Server 2019 Standard 
variable "db_instance_ami" {
  description = "Database Server Windows AMI ID."
  type        = string
  default     = "ami-0b8faab7d97993e1f"
}

variable "db_instance_number" {
  description = "Database Server Windows instance count."
  type        = string
  default     = "1"
}

variable "db_instance_type" {
  description = "Database Server Windows size."
  type        = string
  default     = "t3.2xlarge"
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
  default     = "cloud_deployment"
}

