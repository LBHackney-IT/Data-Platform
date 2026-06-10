resource "aws_lakeformation_data_lake_settings" "data_platform" {
  admins = [
    "arn:aws:iam::${var.aws_deploy_account_id}:role/${var.aws_deploy_iam_role_name}"
  ]

  create_database_default_permissions {
    principal   = "IAM_ALLOWED_PRINCIPALS"
    permissions = ["ALL"]
  }

  create_table_default_permissions {
    principal   = "IAM_ALLOWED_PRINCIPALS"
    permissions = ["ALL"]
  }
}
