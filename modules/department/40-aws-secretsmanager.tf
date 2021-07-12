resource "aws_secretsmanager_secret" "redshift_cluster_parking_credentials" {
  tags = var.tags

  name        = "${var.identifier_prefix}/${local.department_identifier}-redshift-cluster-user"
  description = "Credentials for the redshift cluster parking user"
  kms_key_id  = var.secrets_manager_kms_key.key_id
}