data "aws_secretsmanager_secret" "redshift_cluster_credentials" {
  name_prefix = "${var.identifier_prefix}/${local.department_identifier}/redshift-cluster-user"
}

data "aws_secretsmanager_secret_version" "redshift_creds" {
  secret_id = data.aws_secretsmanager_secret.redshift_cluster_credentials.id
}
