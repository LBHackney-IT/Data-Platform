variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "short_identifier_prefix" {
  description = "Project wide resource short identifier prefix"
  type        = string
}

variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to deploy the datahub containers into"
  type        = string
}

variable "vpc_subnet_ids" {
  description = "A list of VPC Subnet IDs the server could be deployed in"
  type        = list(string)
}

variable "kafka_properties" {
  description = "Properties of the kafka data source DataHub will connect to"
  type = object({
    kafka_zookeeper_connect = string
    kafka_bootstrap_server  = string
  })
}

variable "schema_registry_properties" {
  description = "Properties of the schema registry data source DataHub will connect to"
  type = object({
    schema_registry_url = string
  })
}

variable "is_live_environment" {
  description = "A flag indicting if we are running in a live environment for setting up automation"
  type        = bool
}

variable "datahub_url" {
  description = "Datahub URL"
  type        = string
}
