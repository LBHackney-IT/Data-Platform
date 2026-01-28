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

# Academy SQL Server credentials for Revenues department
resource "aws_secretsmanager_secret" "revenues_academy_sql_server_creds" {
  name        = "/revenues/academy_sql_server_creds"
  description = "SQL Server credentials for Academy database ingestion - Revenues department"
  tags        = module.tags.values
}

resource "aws_secretsmanager_secret_version" "revenues_academy_sql_server_creds" {
  secret_id = aws_secretsmanager_secret.revenues_academy_sql_server_creds.id
  secret_string = jsonencode({
    value = "UPDATE_IN_CONSOLE"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Academy SQL Server credentials for Benefits and Housing Needs department
resource "aws_secretsmanager_secret" "bens_housing_needs_academy_sql_server_creds" {
  name        = "/bens-housing-needs/academy_sql_server_creds"
  description = "SQL Server credentials for Academy database ingestion - Benefits and Housing Needs department"
  tags        = module.tags.values
}

resource "aws_secretsmanager_secret_version" "bens_housing_needs_academy_sql_server_creds" {
  secret_id = aws_secretsmanager_secret.bens_housing_needs_academy_sql_server_creds.id
  secret_string = jsonencode({
    value = "UPDATE_IN_CONSOLE"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}


resource "aws_secretsmanager_secret" "qlik_cloud" {
  name        = "/${module.department_data_and_insight_data_source.identifier}/qlik-cloud"
  description = "Qlik Cloud credentials containing tenant_hostname and api_key"
  tags        = module.tags.values
}

resource "aws_secretsmanager_secret_version" "qlik_cloud" {
  secret_id = aws_secretsmanager_secret.qlik_cloud.id
  secret_string = jsonencode({
    tenant_hostname = "UPDATE_IN_CONSOLE"
    api_key         = "UPDATE_IN_CONSOLE"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "parking_team_times" {
  name        = "/parking/team-times-api"
  description = "Team Times API endpoint and key"
  tags        = module.tags.values
}

resource "aws_secretsmanager_secret_version" "parking_team_times" {
  secret_id = aws_secretsmanager_secret.parking_team_times.id
  secret_string = jsonencode({
    api_enpoint = "UPDATE_IN_CONSOLE",
    api_key = "UPDATE_IN_CONSOLE"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}
