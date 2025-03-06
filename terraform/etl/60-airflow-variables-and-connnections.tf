### Airflow Alerts

resource "aws_secretsmanager_secret" "google_chat_webhook_mapping" {
  name        = "airflow/variables/google_chat_webhook_mapping"
  description = "Mapping of department DAG tags to Google Spaces webhooks for failure alerts."
  tags        = module.tags.values
}

resource "aws_secretsmanager_secret_version" "google_chat_webhook_mapping" {
  secret_id = aws_secretsmanager_secret.google_chat_webhook_mapping.id
  secret_string = jsonencode({
    lower_department_name = "UPDATE_WITH_WEBHOOK_IN_CONSOLE"
  })


  lifecycle {
    ignore_changes = [secret_string]
  }
}



### Alloy

resource "aws_secretsmanager_secret" "alloy_api_key" {
  name        = "airflow/variables/alloy_api_key"
  description = "API key for accessing the Alloy service"
  tags        = module.tags.values
}

resource "aws_secretsmanager_secret_version" "alloy_api_key" {
  secret_id     = aws_secretsmanager_secret.alloy_api_key.id
  secret_string = "UPDATE_IN_CONSOLE"


  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "alloy_connection" {
  name        = "airflow/connections/alloy_api_connection"
  description = "Connection for the Alloy API"
  tags        = module.tags.values
}


resource "aws_secretsmanager_secret_version" "alloy_connection" {
  secret_id = aws_secretsmanager_secret.alloy_connection.id
  secret_string = jsonencode({
    host = "https://api.uk.alloyapp.io"
  })
}


# Store the KMS key ARNs for the refined, raw, and trusted zones as airflow variables in Secrets Manager
locals {
  kms_keys = {
    refined_zone = module.refined_zone_data_source.kms_key_arn
    raw_zone     = module.raw_zone_data_source.kms_key_arn
    trusted_zone = module.trusted_zone_data_source.kms_key_arn
  }
}

resource "aws_secretsmanager_secret" "kms_keys" {
  for_each = local.kms_keys

  name = "airflow/variables/${each.key}_kms_key"
  tags = module.tags.values
}

resource "aws_secretsmanager_secret_version" "kms_keys" {
  for_each = local.kms_keys

  secret_id     = aws_secretsmanager_secret.kms_keys[each.key].id
  secret_string = each.value
}
