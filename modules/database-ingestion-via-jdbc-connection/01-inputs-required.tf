variable "jdbc_connection_url" {
  description = "The JDBC Connection Url used to connect to the source database"
  type        = string
}

variable "name" {
  description = "Name of the dataset that will be ingested."
}

variable "jdbc_connection_description" {
  description = "The type of connection and database that is used for data ingestion"
  type        = string
}

variable "database_availability_zone" {
  description = "Availability zone of the database to be used in the Glue connection"
  type        = string
}

variable "database_secret_name" {
  description = "Name of secret for database credentials"
  type = string
}

variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "jdbc_connection_subnet_id" {
  description = "Subnet used for the JDBC connection"
  type        = string
}

variable "identifier_prefix" {
  description = "Project wide short resource identifier prefix"
  type        = string
}

variable "vpc_id" {
  description = "Id of Data Platform VPC"
  type        = string
}

