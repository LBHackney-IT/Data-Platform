resource "aws_secretsmanager_secret" "redshift_cluster_credentials" {
  tags = var.tags

  name_prefix = "${var.identifier_prefix}/${local.department_identifier}/redshift-cluster-user"
  description = "Credentials for the redshift cluster ${local.department_identifier} user"
  kms_key_id  = var.secrets_manager_kms_key.key_id
}

resource "aws_ssm_parameter" "redshift_cluster_credentials_arn" {
  tags = var.tags

  name        = "/${var.identifier_prefix}/redshift/${local.department_identifier}/redshift_cluster_credentials_arn"
  type        = "SecureString"
  description = "ARN of the departments redshift cluster credential secret"
  value       = aws_secretsmanager_secret.redshift_cluster_credentials.arn
}

resource "random_password" "redshift_password" {
  length      = 24
  special     = false
  numeric     = true
  min_numeric = 1
  upper       = true
  min_upper   = 1
  lower       = true
  min_lower   = 1
}

locals {
  hostname = length(var.redshift_ip_addresses) == 1 ? var.redshift_ip_addresses[0] : "One of ${var.redshift_ip_addresses[0]} OR ${var.redshift_ip_addresses[1]}"
  redshift_creds = {
    "Host Name or IP" = local.hostname,
    "Port"            = var.redshift_port
    "Database"        = "data_platform"
    "Username"        = local.department_identifier
    "Password"        = random_password.redshift_password.result
  }
}

resource "aws_secretsmanager_secret_version" "redshift_creds" {
  secret_id     = aws_secretsmanager_secret.redshift_cluster_credentials.id
  secret_string = jsonencode(local.redshift_creds)
}
