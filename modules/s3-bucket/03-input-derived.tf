data "aws_caller_identity" "current" {}

locals {
  current_arn = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
  ]
  role_arns_to_share_access_with = [for x in concat(var.role_arns_to_share_access_with, local.current_arn) : x if x != null]
}
