locals {
  deploy_sso = var.google_group_display_name != null && var.is_live_environment
}

data "aws_ssoadmin_permission_set" "department" {
  count    = local.deploy_sso ? 1 : 0
  provider = aws.aws_hackit_account
  name     = "DataPlatform${local.department_pascalcase}${title(var.environment)}"
}
