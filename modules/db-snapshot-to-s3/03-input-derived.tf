data "aws_caller_identity" "current" {}

locals {
  lambda_timeout = 900
}
