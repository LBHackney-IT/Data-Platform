/* This defines any required input variables. This are provided in environemtn specific .tfvars for ease of use.
   See https://www.terraform.io/docs/configuration/variables.html
*/

// SDLC Meta-data
variable "environment" {
  description = "Name of the environment, must be one of 'dev', 'stg', 'prod' or 'mgmt'."
  type        = string

  validation {
    condition = (
      var.environment == "dev" || var.environment == "stg" || var.environment == "prod" || var.environment == "mgmt"
    )
    error_message = "The environment must be one of 'dev', 'stg', 'prod' or 'mgmt'."
  }
}

# Hackney Organisation Meta-data
variable "department" {
  description = "Name of the product e.g. 'RevenueAndBenefits'."
  type        = string

  validation {
    condition = (
      length(var.department) > 0 &&
      length(var.department) < 256 &&
      length(regexall("^[a-zA-Z0-9- ]+", var.department)) == 1
    )
    error_message = "The value cannot be a blank string, and must contain only upper or lowercase alphabet (a-zA-Z) or numeral (0-9) characters."
  }
}

variable "application" {
  description = "Name of the application e.g. 'Academy'."
  type        = string

  validation {
    condition = (
      length(var.application) > 0 &&
      length(var.application) < 256 &&
      length(regexall("^[a-zA-Z0-9]+", var.application)) == 1
    )
    error_message = "The value cannot be a blank string, and must contain only lowercase alphabet (a-z), numeral (0-9) or underscore (_) characters."
  }
}
