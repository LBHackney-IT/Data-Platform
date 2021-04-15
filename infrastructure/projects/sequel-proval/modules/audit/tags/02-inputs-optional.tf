/* This defines any optional input variables. The values here are set to defaults that
   would work with most anticipated use cases but may required to be overriden.

   See https://www.terraform.io/docs/configuration/variables.html
*/

// SDLC Meta-data
variable "phase" {
  description = "Phase of the infrastructure, useful for tracking projects phases or evolutions in infrastructure e.g. 'phase_1'."
  type        = string
  default     = "default"

  validation {
    condition = (
      length(var.phase) > 0 &&
      length(var.phase) < 256 &&
      length(regexall("^[a-z0-9_]+", var.phase)) == 1
    )
    error_message = "The value cannot be a blank string, and must contain only lowercase alphabet (a-z), numeral (0-9) or underscore (_) characters."
  }
}

variable "automation_build_url" {
  description = "URL of the automation build, must be one of 'dev', 'stg' or 'prod'."
  type        = string
  default     = "unknown"

  validation {
    condition = (
      var.automation_build_url == "unknown" || length(regexall("(\\b(https?|ftp|file)://)?[-A-Za-z0-9+&@#/%?=~_|!:,.;]+[-A-Za-z0-9+&@#/%=~_|]", var.automation_build_url)) == 3
    )
    error_message = "The value must be a valid URL."
  }
}

// Hackney Organisation Meta-data
variable "team" {
  description = "Team that is responsible for the infrastructure solution e.g. 'cloud_deployment'."
  type        = string
  default     = "cloud_deployment"

  validation {
    condition = (
      length(var.team) > 0 &&
      length(var.team) < 256 &&
      length(regexall("^[a-z0-9_]+", var.team)) == 1
    )
    error_message = "The value cannot be a blank string, and must contain only lowercase alphabet (a-z), numeral (0-9) or underscore (_) characters."
  }
}

variable "project" {
  description = "Project related to the infrastructure, useful for tracking projects phases or evolutions in infrastructure e.g. 'apollo'."
  type        = string
  default     = "internal"

  validation {
    condition = (
      length(var.project) > 0 &&
      length(var.project) < 256 &&
      length(regexall("^[a-z0-9_]+", var.project)) == 1
    )
    error_message = "The value cannot be a blank string, and must contain only lowercase alphabet (a-z), numeral (0-9) or underscore (_) characters."
  }
}

variable "stack" {
  description = "Stack related to the infrastructure, useful for tracking shared big ticket infrastructure costs e.g. 'appstream'."
  type        = string
  default     = "standalone"

  validation {
    condition = (
      length(var.stack) > 0 &&
      length(var.stack) < 256 &&
      length(regexall("^[a-z0-9_]+", var.stack)) == 1
    )
    error_message = "The value cannot be a blank string, and must contain only lowercase alphabet (a-z), numeral (0-9) or underscore (_) characters."
  }
}

// Hackney Security Meta-data
variable "confidentiality" {
  description = "Data confentiality of the infrastructure"
  type        = string
  default     = "internal"

  validation {
    condition = (
      var.confidentiality == "public" || var.confidentiality == "internal" || var.confidentiality == "restricted"
    )
    error_message = "The confidentiality must be one of 'public', 'internal' or 'restricted'."
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
