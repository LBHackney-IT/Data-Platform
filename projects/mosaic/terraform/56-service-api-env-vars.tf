# For docdb-public-key, mosaic-api-url and mosaic-api-token, these have been
# manually created to avoid exposure of their values in code.

resource "aws_secretsmanager_secret" "service_api_show_historic_data_feature_flag" {
  provider = aws.core

  name = "social_care_case_viewer_api_show_historic_data"
}

resource "aws_secretsmanager_secret_version" "service_api_show_historic_data_feature_flag" {
  provider = aws.core

  secret_id     = aws_secretsmanager_secret.service_api_show_historic_data_feature_flag.id
  secret_string = var.service_api_show_historic_data_feature_flag
}

resource "aws_ssm_parameter" "service_api_platform_api_url" {
  provider = aws.core

  name  = format("/social-care-case-viewer-api/mosaic-%s/social-care-platform-api-url", lower(var.environment))
  type  = "String"
  value = "https://${var.platform_api_id}.execute-api.eu-west-2.amazonaws.com/${local.environment_long}/api/v1/"

  tags = module.tags.values
}

data "aws_api_gateway_api_key" "service_api_platform_api_key" {
  provider = aws.core

  id = var.platform_api_key_id
}

resource "aws_ssm_parameter" "service_api_platform_api_key" {
  provider = aws.core

  name  = format("/social-care-case-viewer-api/mosaic-%s/social-care-platform-api-token", lower(var.environment))
  type  = "SecureString"
  value = data.aws_api_gateway_api_key.service_api_platform_api_key.value

  tags = module.tags.values
}
