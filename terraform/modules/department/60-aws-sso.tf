locals {
  deploy_sso = var.google_group_display_name != null && var.is_live_environment
}

resource "aws_ssoadmin_permission_set" "department" {
  count = local.deploy_sso ? 1 : 0

  provider = aws.aws_hackit_account

  // Name must not exceed 32 characters
  name             = "DataPlatform${local.department_pascalcase}${title(var.environment)}"
  description      = "This is a test permission set created by Terraform"
  instance_arn     = var.sso_instance_arn
  session_duration = "PT12H"
  tags             = var.tags
}

resource "aws_ssoadmin_managed_policy_attachment" "department_s3" {
  count = local.deploy_sso ? 1 : 0

  provider = aws.aws_hackit_account

  instance_arn       = var.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.department[0].arn
  managed_policy_arn = var.environment == "stg" ? aws_iam_policy.s3_access.arn : aws_iam_policy.read_only_s3_access.arn
}

resource "aws_ssoadmin_managed_policy_attachment" "department_glue" {
  count = local.deploy_sso ? 1 : 0

  provider = aws.aws_hackit_account

  instance_arn       = var.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.department[0].arn
  managed_policy_arn = var.environment == "stg" ? aws_iam_policy.glue_access.arn : aws_iam_policy.read_only_glue_access.arn
}

resource "aws_ssoadmin_managed_policy_attachment" "department_secrets" {
  count = local.deploy_sso ? 1 : 0

  provider = aws.aws_hackit_account

  instance_arn       = var.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.department[0].arn
  managed_policy_arn = aws_iam_policy.secrets_manager_read_only.arn
}

resource "aws_iam_policy" "sso_department_additional_policy" {
  count = local.deploy_sso ? 1 : 0

  name        = lower("${var.identifier_prefix}-${local.department_identifier}-sso-additional-policy")
  description = "Additional SSO policy for ${local.department_identifier} department in ${var.environment} environment"
  policy = var.environment == "stg" ? (
    local.create_notebook ?
    data.aws_iam_policy_document.sso_staging_additional_with_notebook.json :
    data.aws_iam_policy_document.sso_staging_additional.json
    ) : (
    data.aws_iam_policy_document.sso_production_additional.json
  )
  tags = var.tags
}

resource "aws_ssoadmin_managed_policy_attachment" "department_additional" {
  count = local.deploy_sso ? 1 : 0

  provider = aws.aws_hackit_account

  instance_arn       = var.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.department[0].arn
  managed_policy_arn = aws_iam_policy.sso_department_additional_policy[0].arn
}

data "aws_identitystore_group" "department" {
  count = local.deploy_sso ? 1 : 0

  provider = aws.aws_hackit_account

  identity_store_id = var.identity_store_id

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = var.google_group_display_name
    }
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
