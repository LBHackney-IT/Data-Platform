resource "aws_secretsmanager_secret" "sheets_credentials" {
  tags = var.tags

  // name_prefix is added here, in case you destroy the secret.
  // Secrets will linger for around 6-7 days in case recovery is required,
  // and you will be unable to create with the same name.
  name_prefix = "${var.identifier_prefix}/${var.department_name}/sheets-credential-"
  description = "Google Service User credentials used by AWS Glue jobs to access Google Sheets"

  kms_key_id = var.secrets_manager_kms_key_id
}

resource "aws_ssm_parameter" "sheets_credentials" {
  tags = var.tags

  name        = "/${var.identifier_prefix}${var.department_name}/secrets_manager/sheets-credential/name"
  type        = "SecureString"
  description = "The name of the google service account sheets credentials secret"
  value       = aws_secretsmanager_secret.sheets_credentials.name
}

resource "aws_secretsmanager_secret_version" "json_credentials_binary" {
  count = var.is_live_environment && var.secret_type == "binary" ? 1 : 0

  secret_id     = aws_secretsmanager_secret.sheets_credentials.id
  secret_binary = google_service_account_key.json_credentials[0].private_key
}

resource "aws_secretsmanager_secret_version" "json_credentials_string" {
  count = var.is_live_environment && var.secret_type == "string" ? 1 : 0

  secret_id     = aws_secretsmanager_secret.sheets_credentials.id
  secret_string = base64decode(google_service_account_key.json_credentials[0].private_key)
}
