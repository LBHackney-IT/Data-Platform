resource "aws_kms_key" "sheets_credentials" {
  tags = module.tags.values

  description             = "${var.project} ${var.environment} - Sheets Credentials"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_secretsmanager_secret" "sheets_credentials_housing" {
  tags = module.tags.values

  name       = "${local.identifier_prefix}-sheets-credentials-housing"
  kms_key_id = aws_kms_key.sheets_credentials.id
}

resource "aws_secretsmanager_secret_version" "housing_json_credentials_secret_version" {
  secret_id     = aws_secretsmanager_secret.sheets_credentials_housing.id
  secret_binary = google_service_account_key.housing_json_credentials.private_key
}
