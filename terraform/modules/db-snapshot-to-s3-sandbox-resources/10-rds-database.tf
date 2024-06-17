
locals {
  sandbox_db_secret   = jsondecode(data.aws_secretsmanager_secret_version.sandbox_db_credentials.secret_string)
  sandbox_db_password = local.sandbox_db_secret["password"]
  postgres_port       = 5432
  database_name       = "${replace(lower(var.identifier_prefix), "/[^a-zA-Z0-9]+/", "_")}_sandbox"
  database_username   = "sandbox_db_admin"
}

resource "aws_security_group" "rds_snapshot_to_s3" {
  provider = aws.aws_sandbox_account
  tags     = var.tags
  name     = "${var.identifier_prefix}-rds-snapshot-to-s3"
  vpc_id   = var.aws_sandbox_vpc_id
}

resource "aws_security_group_rule" "rds_snapshot_to_s3_ingress" {
  provider                 = aws.aws_sandbox_account
  description              = "Allow inboud from bastion host on postgres port"
  type                     = "ingress"
  from_port                = local.postgres_port
  to_port                  = local.postgres_port
  protocol                 = "TCP"
  security_group_id        = aws_security_group.rds_snapshot_to_s3.id
  source_security_group_id = aws_security_group.bastion.id
}

resource "random_password" "sandbox_db_password" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "sandbox_db_credentials" {
  provider = aws.aws_sandbox_account

  recovery_window_in_days = 0
  name                    = "/database-credentials/${var.identifier_prefix}-rds-snapshot-to-s3-sandbox-db"
}

resource "aws_secretsmanager_secret_version" "sandbox_db_credentials" {
  provider = aws.aws_sandbox_account

  secret_id = aws_secretsmanager_secret.sandbox_db_credentials.id
  secret_string = jsonencode({
    username      = local.database_username,
    password      = "${random_password.sandbox_db_password.result}",
    database_name = local.database_name
  })
}

data "aws_secretsmanager_secret" "sandbox_db_credentials" {
  provider = aws.aws_sandbox_account
  name     = aws_secretsmanager_secret.sandbox_db_credentials.name
}

data "aws_secretsmanager_secret_version" "sandbox_db_credentials" {
  provider  = aws.aws_sandbox_account
  secret_id = data.aws_secretsmanager_secret.sandbox_db_credentials.id
}


resource "aws_db_subnet_group" "sandbox_db_subnet_group" {
  provider   = aws.aws_sandbox_account
  name       = "${var.identifier_prefix}-sandbox-db-subnet-group"
  subnet_ids = var.aws_sandbox_subnet_ids
}

data "aws_iam_policy_document" "key_policy" {
  statement {
    effect = "Allow"
    actions = [
      "kms:*"
    ]
    resources = [
      "*"
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.aws_sandbox_account_id}:root"]
    }
  }

  #Enable this as the last step once all other resources have been deployed
  # statement {
  #   effect = "Allow"
  #   actions = [
  #     "kms:*"
  #   ]
  #   resources = [
  #     "*"
  #   ]
  #   principals {
  #     type = "AWS"
  #     identifiers = [
  #       "arn:aws:iam::${var.aws_sandbox_account_id}:root",
  #       "arn:aws:iam::${var.aws_sandbox_account_id}:role/${var.identifier_prefix}-rds-snapshot-to-s3-lambda"]
  #   }
  # }
}

resource "aws_kms_key" "key" {
  provider = aws.aws_sandbox_account
  tags     = var.tags

  description             = "${var.identifier_prefix} rds snapshot to cross account s3 sandbox db key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = data.aws_iam_policy_document.key_policy.json
}

resource "aws_kms_alias" "sandbox_db_key_alias" {
  provider      = aws.aws_sandbox_account
  name          = lower("alias/${var.identifier_prefix}-sandbox-db")
  target_key_id = aws_kms_key.key.key_id
}

resource "aws_db_instance" "rds_sandbox_snapshot_to_s3_postgres" {

  identifier            = "${var.identifier_prefix}-rds-snapshot-to-cross-account-s3-sandbox-db"
  engine                = "postgres"
  engine_version        = "14.6"
  instance_class        = "db.t3.micro"
  allocated_storage     = 5
  max_allocated_storage = 6
  db_name               = local.database_name
  username              = local.database_username
  password              = local.sandbox_db_password
  port                  = local.postgres_port

  vpc_security_group_ids = [aws_security_group.rds_snapshot_to_s3.id]
  db_subnet_group_name   = aws_db_subnet_group.sandbox_db_subnet_group.name

  maintenance_window = "sun:04:00-sun:04:30"
  backup_window      = "00:01-00:31"

  backup_retention_period      = 1
  monitoring_interval          = 0
  storage_encrypted            = true
  skip_final_snapshot          = true
  deletion_protection          = false
  multi_az                     = false
  performance_insights_enabled = false
  publicly_accessible          = false
  apply_immediately            = true
  kms_key_id                   = aws_kms_key.key.arn

  provider = aws.aws_sandbox_account
}
