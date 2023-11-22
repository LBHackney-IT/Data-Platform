resource "aws_redshiftserverless_namespace" "namespace" {
  tags = var.tags

  namespace_name = var.namespace_name

  admin_user_password  = aws_secretsmanager_secret_version.master_password.secret_string
  admin_username       = var.admin_username
  db_name              = var.db_name
  default_iam_role_arn = aws_iam_role.redshift_serverless_role.arn
  iam_roles            = [aws_iam_role.redshift_serverless_role.arn]
  kms_key_id           = aws_kms_key.key.arn

  # #this is not ideal and can cause headaches if roles need tweaking, but seems to be a known issue https://github.com/hashicorp/terraform-provider-aws/issues/26624
  # lifecycle {
  #   ignore_changes = [
  #     iam_roles
  #   ]
  # }
}

