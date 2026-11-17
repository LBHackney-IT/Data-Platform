/*
Staging-only Blackbaud migration infrastructure.

Creates one private SQL Server RDS instance and enables native .bak restoration.
Backup files are read from the existing dataplatform-stg-landing-zone bucket
under data-and-insight/manual/blackbaud/.

Upload each backup to the corresponding prefix and restore it separately:
- data-and-insight/manual/blackbaud/test_backup/BakDemo.bak -> blackbaud_test
- data-and-insight/manual/blackbaud/first_backup/<filename>.bak -> blackbaud_first_backup
- data-and-insight/manual/blackbaud/cutover_backup/<filename>.bak -> blackbaud_cutover_backup

All three databases share instance compute and storage. SQL Server 2022
Express limits each database to 10 GB.
*/

# Common configuration
locals {
  blackbaud_migration_enabled = local.is_live_environment && var.environment == "stg"
  blackbaud_migration_name    = "${local.identifier_prefix}-blackbaud-migration"
  blackbaud_backup_prefix     = "data-and-insight/manual/blackbaud"
  blackbaud_migration_tags = merge(module.tags.values, {
    Name = local.blackbaud_migration_name
  })
}

# Existing staging resources
data "aws_subnets" "blackbaud_private" {
  count = local.blackbaud_migration_enabled ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_ssm_parameter.aws_vpc_id.value]
  }

  filter {
    name   = "tag:Type"
    values = ["private"]
  }
}

# Restore permissions for the landing-zone Blackbaud prefix
resource "aws_iam_role" "blackbaud_restore" {
  count = local.blackbaud_migration_enabled ? 1 : 0
  name  = "${local.blackbaud_migration_name}-restore"
  tags  = local.blackbaud_migration_tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Action    = "sts:AssumeRole"
        Principal = { Service = "rds.amazonaws.com" }
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = var.aws_deploy_account_id
          }
          ArnEquals = {
            "aws:SourceArn" = [
              "arn:aws:rds:${var.aws_deploy_region}:${var.aws_deploy_account_id}:db:${local.blackbaud_migration_name}",
              "arn:aws:rds:${var.aws_deploy_region}:${var.aws_deploy_account_id}:og:${local.blackbaud_migration_name}"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "blackbaud_restore" {
  count = local.blackbaud_migration_enabled ? 1 : 0
  name  = "read-blackbaud-backups"
  role  = aws_iam_role.blackbaud_restore[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetBucketLocation"]
        Resource = module.landing_zone_data_source.bucket_arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = module.landing_zone_data_source.bucket_arn
        Condition = {
          StringLike = {
            "s3:prefix" = [
              local.blackbaud_backup_prefix,
              "${local.blackbaud_backup_prefix}/*"
            ]
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:GetObjectAttributes"]
        Resource = "${module.landing_zone_data_source.bucket_arn}/${local.blackbaud_backup_prefix}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:DescribeKey"]
        Resource = module.landing_zone_data_source.kms_key_arn
      }
    ]
  })
}

# Native .bak restoration
resource "aws_db_option_group" "blackbaud_restore" {
  count                    = local.blackbaud_migration_enabled ? 1 : 0
  name                     = local.blackbaud_migration_name
  option_group_description = "Native restoration of Blackbaud SQL Server backups"
  engine_name              = "sqlserver-ex"
  major_engine_version     = "16.00"
  tags                     = local.blackbaud_migration_tags

  option {
    option_name = "SQLSERVER_BACKUP_RESTORE"

    option_settings {
      name  = "IAM_ROLE_ARN"
      value = aws_iam_role.blackbaud_restore[0].arn
    }
  }

  depends_on = [aws_iam_role_policy.blackbaud_restore]
}

# SQL Server instance
module "blackbaud_migration_rds" {
  count  = local.blackbaud_migration_enabled ? 1 : 0
  source = "git::https://github.com/LBHackney-IT/aws-rds-lbh.git?ref=31bbceeb3da007096f81122804bc1fe962f802c5"

  application             = local.blackbaud_migration_name
  environment             = var.environment
  db_identifier           = local.blackbaud_migration_name
  db_subnet_group_name    = local.blackbaud_migration_name
  db_engine               = "sqlserver-ex"
  db_engine_version       = "16.00.4305.5.v1"
  db_family               = "sqlserver-ex-16.0"
  db_major_engine_version = "16.00"
  db_instance_class       = "db.t3.small"
  db_port                 = "1433"
  db_username             = "dbadmin"

  # SQL Server 2022 Express has a 10 GB per-database limit, independent of storage.
  db_allocated_storage        = 20
  db_max_allocated_storage    = 50
  db_multi_az                 = false
  db_storage_encrypted        = true
  db_deletion_protection      = true
  manage_master_user_password = true
  kms_key_arn                 = null

  vpc_id                             = data.aws_ssm_parameter.aws_vpc_id.value
  subnet_ids                         = data.aws_subnets.blackbaud_private[0].ids
  create_db_option_group             = false
  option_group_name                  = aws_db_option_group.blackbaud_restore[0].name
  tags                               = local.blackbaud_migration_tags
  allowed_security_group_ids         = []
  allowed_security_group_name_filter = data.aws_security_group.blackbaud_ecs[0].name
}
