data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "liberator_data_sftp_server_host" {
  name = "/liberator-data/sftp-server-host"
}

data "aws_ssm_parameter" "liberator_data_sftp_server_username" {
  name = "/liberator-data/sftp-server-username"
}

data "aws_ssm_parameter" "liberator_data_sftp_server_password" {
  name = "/liberator-data/sftp-server-password"
}

locals {
  lambda_timeout                      = 900
  liberator_data_sftp_server_host     = data.aws_ssm_parameter.liberator_data_sftp_server_host
  liberator_data_sftp_server_username = data.aws_ssm_parameter.liberator_data_sftp_server_username
  liberator_data_sftp_server_password = data.aws_ssm_parameter.liberator_data_sftp_server_password
}
