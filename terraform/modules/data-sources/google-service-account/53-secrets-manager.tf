data "aws_secretsmanager_secret" "sheets_credentials" {
  name_ = data.aws_ssm_parameter.sheets_credentials_name.value
}

data "aws_ssm_parameter" "sheets_credentials_name" {
  name = "/${var.identifier_prefix}/secrets_manager/${var.department_name}/sheets-credential/name"
}
