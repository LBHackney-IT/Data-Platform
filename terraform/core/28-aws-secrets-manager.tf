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
  name_prefix = "${local.identifier_prefix}/${module.department_housing_repairs.identifier}/sheets-credential-housing-"

  kms_key_id = aws_kms_key.secrets_manager_key.id
}

resource "aws_ssm_parameter" "sheets_credentials_housing_name" {
  tags = module.tags.values

  name        = "/${local.identifier_prefix}/secrets_manager/sheets_credentials_housing/name"
  type        = "SecureString"
  description = "The name of the housing sheets secret"
  value       = aws_secretsmanager_secret.sheets_credentials_housing.name
}

resource "aws_ssm_parameter" "sheets_credentials_housing_arn" {
  tags = module.tags.values

  name        = "/${local.identifier_prefix}/secrets_manager/sheets_credentials_housing/arn"
  type        = "SecureString"
  description = "The arn of the housing sheets secret"
  value       = aws_secretsmanager_secret.sheets_credentials_housing.arn
}

resource "aws_secretsmanager_secret_version" "housing_json_credentials_secret_version" {
  count = local.is_live_environment ? 1 : 0

  secret_id     = aws_secretsmanager_secret.sheets_credentials_housing.id
  secret_binary = google_service_account_key.housing_json_credentials[0].private_key
}
