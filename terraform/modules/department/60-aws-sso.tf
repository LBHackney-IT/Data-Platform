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

resource "aws_ssoadmin_permission_set_inline_policy" "department" {
  count = local.deploy_sso ? 1 : 0

  provider = aws.aws_hackit_account

  inline_policy      = var.environment == "stg" ? data.aws_iam_policy_document.sso_staging_user_policy.json : data.aws_iam_policy_document.sso_production_user_policy.json
  instance_arn       = var.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.department[0].arn
}

resource "aws_ssoadmin_customer_managed_policy_attachment" "departmental_cloudwatch_ecs_logs" {
  count = local.deploy_sso ? 1 : 0

  provider = aws.aws_hackit_account

  instance_arn       = var.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.department[0].arn

  customer_managed_policy_reference {
    name = aws_iam_policy.departmental_cloudwatch_and_ecs_logs_access.name
    path = "/"
  }
}

# Attach CloudTrail access policy to SSO (data-and-insight only)
resource "aws_ssoadmin_customer_managed_policy_attachment" "cloudtrail_access" {
  count = local.deploy_sso && local.department_identifier == "data-and-insight" && var.cloudtrail_bucket != null ? 1 : 0

  provider = aws.aws_hackit_account

  instance_arn       = var.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.department[0].arn

  customer_managed_policy_reference {
    name = aws_iam_policy.cloudtrail_access_policy[0].name
    path = "/"
  }
}

# Attach DataHub config access policy to SSO (data-and-insight only)
resource "aws_ssoadmin_customer_managed_policy_attachment" "datahub_config_access" {
  count = local.deploy_sso && local.department_identifier == "data-and-insight" && var.datahub_config_bucket != null ? 1 : 0

  provider = aws.aws_hackit_account

  instance_arn       = var.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.department[0].arn

  customer_managed_policy_reference {
    name = aws_iam_policy.datahub_config_access_policy[0].name
    path = "/"
  }
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
