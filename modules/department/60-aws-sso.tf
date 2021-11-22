locals {
  deploy_sso = var.google_group_display_name != null && var.is_live_environment
}

resource "aws_ssoadmin_permission_set" "department" {
  count = local.deploy_sso ? 1 : 0

  provider = aws.aws_hackit_account

  // Name must not exceed 32 characters
  name             = "DataPlatform${local.department_pascalcase}"
  description      = "This is a test permission set created by Terraform"
  instance_arn     = var.sso_instance_arn
  session_duration = "PT12H"
  tags             = var.tags
}

resource "aws_ssoadmin_permission_set_inline_policy" "department" {
  count = local.deploy_sso ? 1 : 0

  provider = aws.aws_hackit_account

  inline_policy      = var.environment == "stg" ? data.aws_iam_policy_document.sso_staging_user_policy.json : data.aws_iam_policy_document.sso_production_user_policy.json
  instance_arn       = var.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.department[0].arn
}

data "aws_identitystore_group" "department" {
  count = local.deploy_sso ? 1 : 0

  provider = aws.aws_hackit_account

  identity_store_id = var.identity_store_id

  filter {
    attribute_path  = "DisplayName"
    attribute_value = var.google_group_display_name
  }
}

data "aws_caller_identity" "data_platform" {
  provider = aws
}

# Link the permission set to the group
resource "aws_ssoadmin_account_assignment" "permission_set_attachment" {
  count              = local.deploy_sso ? 1 : 0
  provider           = aws.aws_hackit_account
  instance_arn       = var.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.department[0].arn

  principal_id   = data.aws_identitystore_group.department[0].group_id
  principal_type = "GROUP"

  target_id   = data.aws_caller_identity.data_platform.account_id
  target_type = "AWS_ACCOUNT"
}
