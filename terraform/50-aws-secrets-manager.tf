resource "aws_kms_key" "sheets_credentials" {
  tags = module.tags.values

  description             = "${var.project} ${var.environment} - Sheets Credentials"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "random_pet" "name" {}

resource "aws_secretsmanager_secret" "sheets_credentials_housing" {
  tags = module.tags.values

  // Random pet name is added here, encase you destroy the secret. Secrets will linger for around 6-7 days encase
  // recovery is required, and you will be unable to create with the same name.
  name       = "${local.identifier_prefix}-sheets-credential-housing-${random_pet.name.id}"
  kms_key_id = aws_kms_key.sheets_credentials.id
}

resource "aws_secretsmanager_secret_version" "housing_json_credentials_secret_version" {
  count         = terraform.workspace == "default" ? 1 : 0
  secret_id     = aws_secretsmanager_secret.sheets_credentials_housing.id
  secret_binary = google_service_account_key.housing_json_credentials[0].private_key
}