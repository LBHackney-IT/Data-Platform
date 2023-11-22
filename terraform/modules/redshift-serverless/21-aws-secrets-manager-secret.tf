resource "random_password" "master_password" {
    length  = 40
    special = false
}

resource "aws_secretsmanager_secret" "master_password" {
    name_prefix = "${var.identifier_prefix}-redshift-serverless-${var.namespace_name}-namespace-master-password"
    description = "Master password for redshift serverless ${var.namespace_name} namespace"
    kms_key_id  = var.secrets_manager_key
}

resource "aws_secretsmanager_secret_version" "master_password" {
    secret_id = aws_secretsmanager_secret.master_password.id
    secret_string = random_password.master_password.result
}
