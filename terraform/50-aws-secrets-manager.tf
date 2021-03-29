resource "aws_secretsmanager_secret" "housing_json_credentials_secret" {
  provider = aws.core
  name     = "${local.identifier_prefix}-housing-json-credentials-secret"
}

resource "aws_secretsmanager_secret_version" "housing_json_credentials_secret_version" {
  provider      = aws.core
  secret_id     = aws_secretsmanager_secret.housing_json_credentials_secret.id
  secret_string = google_service_account_key.housing_json_credentials.private_key
}
