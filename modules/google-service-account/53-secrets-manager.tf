
resource "aws_secretsmanager_secret" "sheets_credentials" {
  tags = var.tags

  // name_prefix is added here, in case you destroy the secret.
  // Secrets will linger for around 6-7 days in case recovery is required,
  // and you will be unable to create with the same name.
  name_prefix = "${var.identifier_prefix}sheets-credential-${var.department_name}-"

  kms_key_id = var.secrets_manager_kms_key_id
}

resource "aws_secretsmanager_secret_version" "json_credentials" {
  secret_id     = aws_secretsmanager_secret.sheets_credentials.id
  secret_binary = google_service_account_key.json_credentials.private_key
}
