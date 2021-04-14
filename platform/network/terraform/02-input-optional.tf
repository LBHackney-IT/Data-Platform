# Shared Services  Infrastructure
# Shared Services  Infrastructure - 10-network
variable "ss_primary_create_igw" {
  description = "Controls if an Internet Gateway is created for public subnets and the related routes that connect them."
  type        = bool
  default     = true
}

variable "ss_primary_enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC."
  type        = bool
  default     = false
}

variable "ss_primary_enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC."
  type        = bool
  default     = true
}

variable "ss_primary_enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways for each of your private networks."
  type        = bool
  default     = false
}

variable "ss_primary_enable_vpn_gateway" {
  description = "Should be true if you want to create a new VPN Gateway resource and attach it to the VPC."
  type        = bool
  default     = true
}

variable "ss_primary_tgwattach_subnet_tags" {
  description = "Additional tags for the tgw attach subnets."
  type        = map(string)
  default     = {}
}

variable "ss_primary_tgwattach_subnet_route_table" {
  description = "Controls if separate route table for tgwattach should be created."
  type        = bool
  default     = true
}

variable "ss_primary_mgmt_subnet_route_table" {
  description = "Controls if separate route table for mangagement should be created."
  type        = bool
  default     = true
}

variable "ss_primary_mgmt_internet_gateway_route" {
  description = "Controls if an internet gateway route for public management access should be created."
  type        = bool
  default     = true
}

variable "ss_primary_mgmt_subnet_tags" {
  description = "Additional tags for the management subnets."
  type        = map(string)
  default     = {}
}

variable "ss_primary_one_nat_gateway_per_az" {
  description = "Should be true if you want only one NAT Gateway per availability zone."
  type        = bool
  default     = false
}

variable "ss_primary_private_subnet_tags" {
  description = "Additional tags for the private subnets."
  type        = map(string)
  default     = {}
}

variable "ss_primary_public_subnet_tags" {
  description = "Additional tags for the public subnets."
  type        = map(string)
  default     = {}
}

variable "ss_primary_region" {
  description = "The AWS region the resources will be deployed into."
  type        = string
  default     = "eu-west-2"
}

variable "ss_primary_single_nat_gateway" {
  description = "Should be true if you want to provision a single shared NAT Gateway across all of your private networks."
  type        = bool
  default     = false
}

# Shared Services  Infrastructure - 11-transit-gateway
# EU1 - Ireland
variable "ss_secondary_amazon_side_asn" {
  description = "The Autonomous System Number (ASN) for the Amazon side of the gateway. By default the TGW is created with the current default Amazon ASN."
  type        = string
  default     = "64513"
}

variable "ss_secondary_create_tgw" {
  description = "Controls if TGW should be created (it affects almost all resources)."
  type        = bool
  default     = true
}

variable "ss_secondary_enable_auto_accept_shared_attachments" {
  description = "Whether resource attachment requests are automatically accepted."
  type        = bool
  default     = true
}

variable "ss_secondary_ram_principals" {
  description = "A list of principals to share TGW with. Possible values are an AWS account ID, an AWS Organizations Organization ARN, or an AWS Organizations Organization Unit ARN."
  type        = list(string)
  default     = []
}

variable "ss_secondary_region" {
  description = "The AWS region the resources will be deployed into."
  type        = string
  default     = "eu-west-1"
}

variable "ss_secondary_share_tgw" {
  description = "Whether to share your transit gateway with other accounts."
  type        = bool
  default     = true
}

variable "ss_secondary_routes_tgw" {
  description = "CIDRs of traffic that should be routed to the secondary Transit Gateway."
  type        = set(string)
  default     = []
}

# EU2 - London
variable "ss_primary_amazon_side_asn" {
  description = "The Autonomous System Number (ASN) for the Amazon side of the gateway. By default the TGW is created with the current default Amazon ASN."
  type        = string
  default     = "64512"
}

variable "ss_primary_create_tgw" {
  description = "Controls if TGW should be created (it affects almost all resources)."
  type        = bool
  default     = true
}

variable "ss_primary_enable_auto_accept_shared_attachments" {
  description = "Whether resource attachment requests are automatically accepted."
  type        = bool
  default     = true
}

variable "ss_primary_ram_principals" {
  description = "A list of principals to share TGW with. Possible values are an AWS account ID, an AWS Organizations Organization ARN, or an AWS Organizations Organization Unit ARN."
  type        = list(string)
  default     = []
}

variable "ss_primary_share_tgw" {
  description = "Whether to share your transit gateway with other accounts."
  type        = bool
  default     = true
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
  default     = "cloud-deployment"
}

# Palo Alto

variable "pa_ha" {
  description = "Controls if Palo ALto firewalls will be deployed in HA configuration"
  type        = bool
  default     = true
}

variable "extended_bootstrap" {
  description = "Controls if Palo ALto bootstrap need to split to two files"
  type        = bool
  default     = false
}

variable "PANFWRegionMap" {
  type = map(string)
  default = {
    "eu-west-2" = "ami-00ad2b17de74dd860",
  }
}


variable "instance_type" {
  description = "Palo Alto instance size"
  type        = string
  default     = "m4.xlarge"
}

