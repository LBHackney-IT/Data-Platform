variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type        = string
}

variable "short_identifier_prefix" {
  description = "Project wide resource short identifier prefix"
  type        = string
}

variable "instance_type" {
  description = "The instance type to use for the Qlik server"
  type        = string
}

variable "ssl_certificate_domain" {
  description = "The domain name associated with an existing AWS Certificate Manager certificate"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC to set the server up in"
  type        = string
}

variable "vpc_subnet_ids" {
  description = "A list of VPC Subnet IDs the server could be deployed in"
  type        = list(string)
}

variable "environment" {
  description = "Enviroment e.g. dev, stg, prod, mgmt."
  type        = string
}

variable "is_production_environment" {
  description = "A flag indicting if we are running in production"
  type        = bool
}

variable "is_live_environment" {
  description = "A flag indicting if we are running in a live environment"
  type        = bool
}

variable "secrets_manager_kms_key" {
  description = "The KMS Key Id to be used to encrypt the secret in secrets manager"
  type = object({
    key_id = string
    arn    = string
  })
}
