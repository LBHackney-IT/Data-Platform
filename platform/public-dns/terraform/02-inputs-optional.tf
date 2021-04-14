# Tags
variable "application" {
  description = "Name of the application."
  type        = string
  default     = "Platform"
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
  default     = "CorePlatform"
}

variable "team" {
  description = "Name of the team responsible for the service."
  type        = string
  default     = "CloudDeployment"
}
