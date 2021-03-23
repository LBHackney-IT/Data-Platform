variable "core_region" {
  description = "The AWS region the resources will be deployed into."
  type        = string
  default     = "eu-west-2"
}

# General
variable "dataplatform_profile" {
  description = "The AWS profile used to authenticate to the Mosaic AWS account."
  type        = string
  default     = "default"
}
