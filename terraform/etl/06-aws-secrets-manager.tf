data "aws_secretsmanager_secret" "sheets_credentials_housing" {
  name = "${local.identifier_prefix}/housing-repairs/sheets-credential-housing-"
}

data "aws_ssm_parameter" "sheets_credentials_housing_name" {
  name = "/${local.identifier_prefix}/secrets_manager/sheets_credentials_housing/name"
}

data "aws_ssm_parameter" "sheets_credentials_housing_arn" {
  name = "/${local.identifier_prefix}/secrets_manager/sheets_credentials_housing/arn"
}

// Tascomi Key
resource "aws_secretsmanager_secret" "tascomi_api_public_key" {
  tags = module.tags.values

  name_prefix = "${local.identifier_prefix}/${module.department_planning.identifier}/tascomi-api-public-key"

  kms_key_id = data.aws_kms_key.secrets_manager_key.id
}

resource "aws_secretsmanager_secret" "tascomi_api_private_key" {
  tags = module.tags.values

  name_prefix = "${local.identifier_prefix}/${module.department_planning.identifier}/tascomi-api-private-key"

  kms_key_id = data.aws_kms_key.secrets_manager_key.id
}

data "aws_kms_key" "secrets_manager_key" {
  key_id = lower("alias/${local.identifier_prefix}-secrets-manager")
}