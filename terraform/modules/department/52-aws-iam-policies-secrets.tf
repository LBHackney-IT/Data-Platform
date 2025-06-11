# =============================================================================
# SECRETS MANAGER IAM POLICIES
# =============================================================================
# This file contains all Secrets Manager related IAM policies for the department module.
# 
# Policies included:
# - Read-only Secrets Manager access
# =============================================================================

# =============================================================================
# SECRETS MANAGER READ-ONLY ACCESS POLICY
# =============================================================================

data "aws_iam_policy_document" "secrets_manager_read_only" {
  # Access to specific department secrets
  statement {
    sid    = "ReadDepartmentSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      aws_secretsmanager_secret.redshift_cluster_credentials.arn,
      module.google_service_account.credentials_secret.arn,
      "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:${var.identifier_prefix}/${local.department_identifier}/*",
      "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:${var.short_identifier_prefix}/${local.department_identifier}*",
      "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:airflow/variables/env-fxe5CD",
      "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:airflow/variables/env-jeCYYl",
    ]
  }

  # General secrets listing permission
  statement {
    sid       = "ListAllSecrets"
    effect    = "Allow"
    actions   = ["secretsmanager:ListSecrets"]
    resources = ["*"]
  }

  # KMS access for secrets decryption
  statement {
    sid    = "KmsSecretsDecryption"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      var.secrets_manager_kms_key.arn
    ]
  }
}

resource "aws_iam_policy" "secrets_manager_read_only" {
  tags   = var.tags
  name   = lower("${var.identifier_prefix}-${local.department_identifier}-secrets-manager-read-only")
  policy = data.aws_iam_policy_document.secrets_manager_read_only.json
} 