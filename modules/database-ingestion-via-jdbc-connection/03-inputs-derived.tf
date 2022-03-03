locals {
  jdbc_connection_name_lowercase = lower(replace(var.jdbc_connection_name, " ", "-"))
  database_name_lowercase = lower(local.database_name)
}
