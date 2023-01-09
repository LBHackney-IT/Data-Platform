locals {
    backup_ami_id = "ami-050960cc7acbe15d9"
}

data "aws_secretsmanager_secret" "pre_production_account_id" {
  count         = var.is_production_environment ? 1 : 0
  name          = "manual/pre-production-account-id"
}

data "aws_secretsmanager_secret_version" "pre_production_account_id" {
  count         = var.is_production_environment ? 1 : 0
  secret_id     = data.aws_secretsmanager_secret.pre_production_account_id[0].id
}

resource "aws_ami_launch_permission" "ami_permissions_for_pre_prod" {
  count         = var.is_production_environment ? 1 : 0
  image_id      = local.backup_ami_id
  account_id    = data.aws_secretsmanager_secret_version.pre_production_account_id[0].secret_string
}
