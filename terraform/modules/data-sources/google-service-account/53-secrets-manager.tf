data "aws_secretsmanager_secret" "sheets_credentials" {
  name_prefix = "${var.identifier_prefix}/${var.department_name}/sheets-credential-"
}

data "aws_secretsmanager_secret_version" "json_credentials_binary" {
  count     = var.is_live_environment && var.secret_type == "binary" ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.sheets_credentials.id
}

data "aws_secretsmanager_secret_version" "json_credentials_string" {
  count     = var.is_live_environment && var.secret_type == "string" ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.sheets_credentials.id
}
