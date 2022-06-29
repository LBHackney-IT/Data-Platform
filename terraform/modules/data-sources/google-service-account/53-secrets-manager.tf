data "aws_secretsmanager_secret" "sheets_credentials" {
  name = data.aws_ssm_parameter.sheets_credentials_name.value
}

data "aws_ssm_parameter" "sheets_credentials_name" {
  name = "/${var.identifier_prefix}${var.department_name}/secrets_manager/sheets-credential/name"
}
