### Alloy

resource "aws_secretsmanager_secret" "alloy_api_key" {
  name        = "/airflow/variables/alloy_api_key"
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
