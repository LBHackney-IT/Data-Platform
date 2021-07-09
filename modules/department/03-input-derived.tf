locals {
  department_identifier = replace(replace(lower(var.name), "/[^a-zA-Z0-9]+/", "-"), "/-+/", "-")
}