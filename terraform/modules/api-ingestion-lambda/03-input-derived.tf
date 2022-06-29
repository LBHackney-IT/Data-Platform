data "aws_caller_identity" "current" {}

locals {
  lambda_name_underscore = replace(lower(var.lambda_name), "/[^a-zA-Z0-9]+/", "_")
}
