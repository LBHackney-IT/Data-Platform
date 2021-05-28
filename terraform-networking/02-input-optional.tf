# Tags
variable "application" {
  description = "Name of the application."
  type        = string
  default     = "DataPlatform"
}

variable "department" {
  description = "Name of the department responsible for the service."
  type        = string
  default     = "HackIT"
}

variable "automation_build_url" {
  description = "The project automation build url."
  type        = string
  default     = "Unknown"
}

variable "confidentiality" {
  description = "The project confidentiality status"
  type        = string
  default     = "Public"
}

variable "custom_tags" {
  description = "Map of custom tags (merged and added to existing other Tags). Must not overlap with any already defined tags."
  type        = map(string)
  default     = {}
}

variable "phase" {
  description = "The project phase."
  type        = string
  default     = "Default"
}

variable "project" {
  description = "The project name."
  type        = string
  default     = "Internal"
}

variable "stack" {
  description = "The project stack."
  type        = string
  default     = "ChangeMe"
}

variable "team" {
  description = "Name of the team responsible for the service."
  type        = string
  default     = "ChangeMe"
}

# Project Variables
variable "core_profile" {
  description = "The AWS profile used to authenticate to the Cedar Advanced AWS account."
  type        = string
  default     = "default"
}

variable "core_enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC."
  type        = bool
  default     = true
}

variable "core_enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC."
  type        = bool
  default     = true
}

variable "core_region" {
  description = "The AWS region the resources will be deployed into."
  type        = string
  default     = "eu-west-2"
}
