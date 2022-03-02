locals {
  jdbc_connection_name_lowercase = lower(replace(var.jdbc_connection_name, " ", "-"))
}
