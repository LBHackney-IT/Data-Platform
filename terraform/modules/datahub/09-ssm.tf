resource "aws_ssm_parameter" "datahub_password" {
  name  = "/${var.identifier_prefix}/datahub/datahub_password"
  type  = "SecureString"
  value = random_password.datahub_secret.result
  tags = merge(var.tags, {
    "Name" : "Datahub Password"
  })
}

resource "random_password" "datahub_secret" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

data "aws_ssm_parameter" "datahub_google_client_id" {
  name = "/dataplatform/datahub/datahub_google_client_id"
}

data "aws_ssm_parameter" "datahub_google_client_secret" {
  name = "/dataplatform/datahub/datahub_google_client_secret"
}

resource "aws_ssm_parameter" "datahub_rds_password" {
  name  = "/${var.identifier_prefix}/datahub/datahub_rds_password"
  type  = "SecureString"
  value = aws_db_instance.datahub.password
  tags = merge(var.tags, {
    "Name" : "Datahub RDS Password"
  })
}

resource "aws_ssm_parameter" "datahub_aws_access_key_id" {
  name  = "/${var.identifier_prefix}/datahub/datahub_aws_access_key_id"
  type  = "SecureString"
  value = aws_iam_access_key.datahub_access_key.id
  tags = merge(var.tags, {
    "Name" : "Datahub AWS Access Key Id"
  })
}

resource "aws_ssm_parameter" "datahub_aws_secret_access_key" {
  name  = "/${var.identifier_prefix}/datahub/datahub_aws_secret_access_key"
  type  = "SecureString"
  value = aws_iam_access_key.datahub_access_key.secret
  tags = merge(var.tags, {
    "Name" : "Datahub AWS Secret Access Key"
  })
}