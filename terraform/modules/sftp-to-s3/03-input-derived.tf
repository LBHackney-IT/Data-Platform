data "aws_caller_identity" "current" {}

data "aws_secretsmanager_secret" "sftp_server_credentials" {
  name = var.sftp_server_credentials
}

data "aws_secretsmanager_secret_version" "sftp_server_credentials" {
  secret_id = data.aws_secretsmanager_secret.sftp_server_credentials.id
}

locals {
  lambda_timeout       = 900
  lambda_memory_size   = 3072
  secret_string        = jsondecode(data.aws_secretsmanager_secret_version.secret_string)
  sftp_server_host     = local.secret_string["sftp_server_host"]
  sftp_server_username = local.secret_string["sftp_server_username"]
  sftp_server_password = local.secret_string["sftp_server_password"]
}
