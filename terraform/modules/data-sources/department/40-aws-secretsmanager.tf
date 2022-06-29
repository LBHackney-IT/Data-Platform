data "aws_secretsmanager_secret" "redshift_cluster_credentials" {
  arn = data.aws_ssm_parameter.redshift_cluster_credentials_arn.value
}

data "aws_ssm_parameter" "redshift_cluster_credentials_arn" {
  name = "/${var.identifier_prefix}/redshift/${local.department_identifier}/redshift_cluster_credentials_arn"
}

data "aws_secretsmanager_secret_version" "redshift_creds" {
  secret_id = data.aws_secretsmanager_secret.redshift_cluster_credentials.id
}
