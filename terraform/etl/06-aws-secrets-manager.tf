data "aws_secretsmanager_secret" "sheets_credentials_housing" {
  arn = data.aws_ssm_parameter.sheets_credentials_housing_arn.value
}

data "aws_ssm_parameter" "sheets_credentials_housing_name" {
  name = "/${local.identifier_prefix}/secrets_manager/sheets_credentials_housing/name"
}

data "aws_ssm_parameter" "sheets_credentials_housing_arn" {
  name = "/${local.identifier_prefix}/secrets_manager/sheets_credentials_housing/arn"
}

data "aws_kms_key" "secrets_manager_key" {
  key_id = lower("alias/${local.identifier_prefix}-secrets-manager")
}

data "aws_secretsmanager_secret" "tascomi_api_public_key" {
  arn = data.aws_ssm_parameter.tascomi_api_public_key_arn.value
}

data "aws_ssm_parameter" "tascomi_api_public_key_arn" {
  name = "/${local.identifier_prefix}/secrets_manager/tascomi_api_public_key/arn"
}

data "aws_secretsmanager_secret" "tascomi_api_private_key" {
  arn = data.aws_ssm_parameter.tascomi_api_private_key_arn.value
}

data "aws_ssm_parameter" "tascomi_api_private_key_arn" {
  name = "/${local.identifier_prefix}/secrets_manager/tascomi_api_private_key/arn"
}