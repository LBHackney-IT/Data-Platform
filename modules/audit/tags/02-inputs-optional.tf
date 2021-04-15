/* This defines any optional input variables. The values here are set to defaults that
   would work with most anticipated use cases but may required to be overriden.

   See https://www.terraform.io/docs/configuration/variables.html
*/

# SDLC Meta-data
variable "phase" {
  description = "Phase of the infrastructure, useful for tracking projects phases or evolutions in infrastructure e.g. 'phase_1'."
  type        = string
  default     = "Default"

  validation {
    condition = (
      length(var.phase) > 0 &&
      length(var.phase) < 256 &&
      length(regexall("^[a-zA-Z0-9]+", var.phase)) == 1
    )
    error_message = "The value cannot be a blank string, and must contain only upper and lowercase alphabet (a-zA-Z) or numeral (0-9) characters."
  }
}

variable "automation_build_url" {
  description = "URL of the automation build, must be a valid URL."
  type        = string
  default     = "Unknown"

  validation {
    condition = (
      var.automation_build_url == "Unknown" || can(regex("http", var.automation_build_url))
    )
    error_message = "The value must be a valid URL."
  }
}

# Hackney Organisation Meta-data
variable "team" {
  description = "Team that is responsible for the infrastructure solution e.g. 'CloudDeployment'."
  type        = string
  default     = "CloudDeployment"

  validation {
    condition = (
      length(var.team) > 0 &&
      length(var.team) < 256 &&
      length(regexall("^[a-zA-Z0-9]+", var.team)) == 1
    )
    error_message = "The value cannot be a blank string, and must contain only upper and lowercase alphabet (a-zA-Z) or numeral (0-9) characters."
  }
}

variable "project" {
  description = "Project related to the infrastructure, useful for tracking projects phases or evolutions in infrastructure e.g. 'Apollo'."
  type        = string
  default     = "Internal"

  validation {
    condition = (
      length(var.project) > 0 &&
      length(var.project) < 256 &&
      length(regexall("^[a-zA-Z0-9]+", var.project)) == 1
    )
    error_message = "The value cannot be a blank string, and must contain only upper and lowercase alphabet (a-zA-Z) or numeral (0-9) characters."
  }
}

variable "stack" {
  description = "Stack related to the infrastructure, useful for tracking shared big ticket infrastructure costs e.g. 'AppStream'."
  type        = string
  default     = "Standalone"

  validation {
    condition = (
      length(var.stack) > 0 &&
      length(var.stack) < 256 &&
      length(regexall("^[a-zA-Z0-9]+", var.stack)) == 1
    )
    error_message = "The value cannot be a blank string, and must contain only upper and lowercase alphabet (a-zA-Z) or numeral (0-9) characters."
  }
}

# Hackney Security Meta-data
variable "confidentiality" {
  description = "Data confidentiality of the infrastructure"
  type        = string
  default     = "Internal"

  validation {
    condition = (
      var.confidentiality == "Public" || var.confidentiality == "Internal" || var.confidentiality == "Restricted"
    )
    error_message = "The confidentiality must be one of 'Public', 'Internal' or 'Restricted'."
  }
}

variable "custom_tags" {
  description = "Map of custom tags (merged and added to existing other Tags). Must not overlap with any already defined tags."
  type        = map(string)
  default     = {}

  validation {
    condition = (

      length(setintersection(toset(keys(var.custom_tags)), toset([
        "automation_build_url",
        "environment",
        "team",
        "department",
        "application",
        "phase",
        "stack",
        "project",
        "confidentiality"
      ]))) == 0
    )
    error_message = "The map cannot contains keys that override the existing defined tags."
  }
}
