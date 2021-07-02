locals {
  department_identifier = replace(replace(lower(var.name), "/[^a-zA-Z0-9]+/", "-"), "/-+/", "-")
  identifier_prefix     = var.identifier_prefix == "" ? "" : "${var.identifier_prefix}-"
}