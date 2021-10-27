resource "aws_kms_key" "secrets_manager_key" {
  tags = module.tags.values

  description             = "${local.identifier_prefix}-secrets-manager-key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_kms_alias" "key_alias" {
  name          = lower("alias/${local.identifier_prefix}-secrets-manager")
  target_key_id = aws_kms_key.secrets_manager_key.key_id
}

// Housing Service Account
resource "aws_secretsmanager_secret" "sheets_credentials_housing" {
  tags = module.tags.values

  // name_prefix is added here, in case you destroy the secret.
  // Secrets will linger for around 6-7 days in case recovery is required,
  // and you will be unable to create with the same name.
  name_prefix = "${local.identifier_prefix}-sheets-credential-housing-"

  kms_key_id = aws_kms_key.secrets_manager_key.id
}

resource "aws_secretsmanager_secret_version" "housing_json_credentials_secret_version" {
  count = local.is_live_environment ? 1 : 0

  secret_id     = aws_secretsmanager_secret.sheets_credentials_housing.id
  secret_binary = google_service_account_key.housing_json_credentials[0].private_key
}

data "aws_iam_policy_document" "housing_secrets_manager_read_only" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      aws_secretsmanager_secret.sheets_credentials_housing.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      aws_kms_key.secrets_manager_key.arn
    ]
  }
}
resource "aws_iam_policy" "housing_secrets_manager_read_only" {
  tags = module.tags.values

  name   = lower("${local.short_identifier_prefix}housing-secrets-manager-read-only")
  policy = data.aws_iam_policy_document.housing_secrets_manager_read_only.json
}

resource "aws_iam_role_policy_attachment" "housing_glue_agent_secrets_manager_read_only" {
  role       = module.department_housing_repairs.glue_role_arn
  policy_arn = aws_iam_policy.glue_can_write_to_cloudwatch.arn
}

// Tascomi Key
resource "aws_secretsmanager_secret" "tascomi_api_public_key" {
  tags = module.tags.values

  name_prefix = "${local.short_identifier_prefix}tascomi-api-public-key"

  kms_key_id = aws_kms_key.secrets_manager_key.id
}

resource "aws_secretsmanager_secret" "tascomi_api_private_key" {
  tags = module.tags.values

  name_prefix = "${local.short_identifier_prefix}tascomi-api-private-key"

  kms_key_id = aws_kms_key.secrets_manager_key.id
}

data "aws_iam_policy_document" "tascomi_secrets_manager_read_only" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      aws_secretsmanager_secret.tascomi_api_public_key.arn,
      aws_secretsmanager_secret.tascomi_api_public_key.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      aws_kms_key.secrets_manager_key.arn
    ]
  }
}
resource "aws_iam_policy" "tascomi_secrets_manager_read_only" {
  tags = module.tags.values

  name   = lower("${local.short_identifier_prefix}tascomi-secrets-manager-read-only")
  policy = data.aws_iam_policy_document.tascomi_secrets_manager_read_only.json
}

resource "aws_iam_role_policy_attachment" "planning_glue_agent_tascomi_secrets_manager_read_only" {
  role       = module.department_housing_repairs.glue_role_arn
  policy_arn = aws_iam_policy.glue_can_write_to_cloudwatch.arn
}