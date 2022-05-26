locals {
  database_and_schema_name_lowercase = var.schema_name == null ? lower(local.database_name) : lower("${local.database_name}-${var.schema_name}")
  iam_role_name                      = var.table_filter == null ? local.database_and_schema_name_lowercase : lower(var.table_filter)
}
