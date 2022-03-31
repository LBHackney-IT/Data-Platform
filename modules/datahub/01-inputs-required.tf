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

variable "environment" {
  description = "Environment e.g. dev, stg, prod, mgmt."
  type        = string
}

variable "operation_name" {
  type        = string
  description = "A unique name for your task definition, ecs cluster and repository."
}

variable "vpc_id" {
  description = "The ID of the VPC to set the server up in"
  type        = string
}

variable "rds_properties" {
  description = "Properties of the RDS data source DataHub will connect to"
  type = object({
    host     = string
    port     = number
    username = string
    password = string
    db_name  = string
  })
}

variable "elasticsearch_properties" {
  description = "Properties of the elastic search data source DataHub will connect to"
  type = object({
    host     = string
    port     = number
    protocol = string
  })
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
    host_name                 = string
    kafkastore_connection_url = string
  })
}
