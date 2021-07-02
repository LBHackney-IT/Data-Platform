locals {
  department_identifier = replace(replace(lower(var.name), "[^a-zA-Z 0-9]+", "-"), "-+", "-")
  identifier_prefix     = var.identifier_prefix == "" ? "" : "${var.identifier_prefix}-"
}