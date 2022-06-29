// Tascomi Key
resource "aws_secretsmanager_secret" "tascomi_api_public_key" {
  tags = module.tags.values

  name_prefix = "${local.identifier_prefix}/${module.department_planning.identifier}/tascomi-api-public-key"

  kms_key_id = aws_kms_key.secrets_manager_key.id
}

resource "aws_ssm_parameter" "tascomi_api_public_key_arn" {
  tags = module.tags.values

  name        = "/${local.identifier_prefix}/secrets_manager/tascomi_api_public_key/arn"
  type        = "SecureString"
  description = "The ARN of the tascomi api public key secret"
  value       = aws_secretsmanager_secret.tascomi_api_public_key.arn
}

resource "aws_secretsmanager_secret" "tascomi_api_private_key" {
  tags = module.tags.values

  name_prefix = "${local.identifier_prefix}/${module.department_planning.identifier}/tascomi-api-private-key"

  kms_key_id = aws_kms_key.secrets_manager_key.id
}

resource "aws_ssm_parameter" "tascomi_api_private_key_arn" {
  tags = module.tags.values

  name        = "/${local.identifier_prefix}/secrets_manager/tascomi_api_private_key/arn"
  type        = "SecureString"
  description = "The ARN of the tascomi api private key secret"
  value       = aws_secretsmanager_secret.tascomi_api_private_key.arn
}