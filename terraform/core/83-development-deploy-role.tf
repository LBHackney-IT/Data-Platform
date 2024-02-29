# This should be one-off deployment per development account since the role is shared between workspaces
# Only enable this if setting a development account from scratch
locals {
  deploy_development_deploy_role = false
}

data "aws_organizations_organization" "org" {
  count = !local.is_live_environment && local.deploy_development_deploy_role ? 1 : 0
}

data "aws_secretsmanager_secret" "admin_sso_role" {
  count = !local.is_live_environment && local.deploy_development_deploy_role ? 1 : 0
  name  = "manual-developer-admin-sso-role-arn"
}

data "aws_secretsmanager_secret_version" "admin_sso_role" {
  count     = !local.is_live_environment && local.deploy_development_deploy_role ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.admin_sso_role[0].id
}

data "aws_iam_policy_document" "development_deploy_assume_role" {
  count = !local.is_live_environment && local.deploy_development_deploy_role ? 1 : 0

  statement {
    sid = "AllowDataPlatformDevelopersDeploymentAdminAccess"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      identifiers = [
        "arn:aws:iam::${var.aws_deploy_account_id}:root"
      ]

      type = "AWS"
    }

    condition {
      test     = "ArnLike"
      variable = "aws:PrincipalArn"
      values   = [data.aws_secretsmanager_secret_version.admin_sso_role[0].secret_string]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [data.aws_organizations_organization.org[0].id]
    }
  }
}

resource "aws_iam_role" "development_deploy_role" {
  count              = !local.is_live_environment && local.deploy_development_deploy_role ? 1 : 0
  name               = "development_deploy"
  assume_role_policy = data.aws_iam_policy_document.development_deploy_assume_role[0].json
}

data "aws_iam_policy_document" "development_deploy_policy_document" {
  count = !local.is_live_environment && local.deploy_development_deploy_role ? 1 : 0

  statement {
    actions   = ["*"]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "development_deploy_policy" {
  count = !local.is_live_environment && local.deploy_development_deploy_role ? 1 : 0

  name   = "development_deploy"
  policy = data.aws_iam_policy_document.development_deploy_policy_document[0].json
}

resource "aws_iam_role_policy_attachment" "development_deploy_role_policy_attachment" {
  count = !local.is_live_environment && local.deploy_development_deploy_role ? 1 : 0

  role       = aws_iam_role.development_deploy_role[0].name
  policy_arn = aws_iam_policy.development_deploy_policy[0].arn
}
