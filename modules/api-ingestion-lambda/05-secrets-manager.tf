data "aws_secretsmanager_secret" "api_credentials_for_lambda" {
  name = var.api_credentials_secret_name
}

data "aws_secretsmanager_secret_version" "api_credentials_for_lambda" {
  secret_id = data.aws_secretsmanager_secret.api_credentials_for_lambda.id
}