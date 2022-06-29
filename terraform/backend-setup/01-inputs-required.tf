# Mandatory variables, that are provided by the GitHub Action CI/CD. The shouldn't be changed!
variable "environment" {
  description = "Environment e.g. Dev, Stg, Prod, Mgmt."
  type        = string
}