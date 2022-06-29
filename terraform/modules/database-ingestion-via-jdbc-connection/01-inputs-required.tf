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

variable "database_secret_name" {
  description = "Name of secret for database credentials"
  type        = string
}

variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "jdbc_connection_subnet" {
  description = "Subnet used for the JDBC connection"
  type = object({
    id                = string
    availability_zone = string
    vpc_id            = string
  })
}

variable "identifier_prefix" {
  description = "Project wide short resource identifier prefix"
  type        = string
}
