locals {
  department_identifier = replace(lower(var.name), "/[^a-zA-Z0-9]+/", "-")
  department_pascalcase = replace(title(replace(var.name, "/[^a-zA-Z0-9]+/", " ")), " ", "")
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
