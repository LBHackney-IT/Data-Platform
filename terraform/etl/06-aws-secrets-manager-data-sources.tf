data "aws_secretsmanager_secret" "sheets_credentials_housing" {
  name_prefix = "${local.identifier_prefix}/housing-repairs/sheets-credential-housing-"
}
data "aws_secretsmanager_secret" "tascomi_api_public_key" {
  name_prefix = "${local.identifier_prefix}/planning/tascomi-api-public-key"
}
data "aws_secretsmanager_secret" "tascomi_api_private_key" {
  name_prefix = "${local.identifier_prefix}/planning/tascomi-api-private-key"
}
data "aws_kms_key" "secrets_manager_key" {
  key_id = lower("alias/${local.identifier_prefix}-secrets-manager")
}