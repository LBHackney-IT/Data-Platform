locals {
    backup_ami_id = "ami-0b2e39229446d572c"
    ec2_tags = {
        BackupPolicy  = title(var.environment)
        Name          = "${var.identifier_prefix}-qlik-sense-restore"
    }
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

#value manually managed in secrets manager on pre-prod
resource "aws_secretsmanager_secret" "production_account_qlik_ec2_ebs_encryption_key_arn" {
  tags        = var.tags
  count       = !var.is_production_environment && var.is_live_environment ? 1 : 0
  name_prefix = "${var.identifier_prefix}-manually-managed-value-production-account-qlik-ec2-ebs-encryption-key-arn"
  kms_key_id  = var.secrets_manager_kms_key.key_id
  description = "Qlik EC2 ESB volume's encryption key arn on production account. This secret value is managed manually."
}

resource "aws_secretsmanager_secret_version" "production_account_qlik_ec2_ebs_encryption_key_arn" {
  count         = !var.is_production_environment && var.is_live_environment ? 1 : 0
  secret_id     = aws_secretsmanager_secret.production_account_qlik_ec2_ebs_encryption_key_arn[0].id
  secret_string = "TODO" #value managed manually
}

data "aws_secretsmanager_secret" "production_account_qlik_ec2_ebs_encryption_key_arn" {
  count         = !var.is_production_environment && var.is_live_environment ? 1 : 0
  name          = aws_secretsmanager_secret.production_account_qlik_ec2_ebs_encryption_key_arn[0].arn
}

data "aws_secretsmanager_secret_version" "production_account_qlik_ec2_ebs_encryption_key_arn" {
  count         = !var.is_production_environment && var.is_live_environment ? 1 : 0
  secret_id     = data.aws_secretsmanager_secret.production_account_qlik_ec2_ebs_encryption_key_arn[0].id
}

resource "aws_iam_policy" "qlik_sense_preprod_can_access_shared_prod_key" {
  count     = !var.is_production_environment && var.is_live_environment ? 1 : 0
  tags      = var.tags

  name      = "${var.identifier_prefix}-qlik-sense-preprod-role-can-access-shared-prod-key"

  policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "AllowQlikEC2RoleAccessToTheSharedProdKey"
          Action = [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
          ]
          Effect   = "Allow"
          Resource = [data.aws_secretsmanager_secret_version.production_account_qlik_ec2_ebs_encryption_key_arn[0].secret_string]
        }
      ]
  })
}

resource "aws_iam_role_policy_attachment" "qlik_sense_prod_key_policy" {
  count         = !var.is_production_environment && var.is_live_environment ? 1 : 0
  role          = aws_iam_role.qlik_sense.id
  policy_arn    = aws_iam_policy.qlik_sense_preprod_can_access_shared_prod_key[0].arn
}

data "aws_secretsmanager_secret" "qlik_sense_ec2_role_arn_on_pre_prod_account" {
  count = var.is_production_environment ? 1 : 0
  name  = "${var.identifier_prefix}-manually-managed-value-qlik-sense-ec2-role-arn-on-pre-prod-account"
}

data "aws_secretsmanager_secret_version" "qlik_sense_ec2_role_arn_on_pre_prod_account" {
  count     = var.is_production_environment ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.qlik_sense_ec2_role_arn_on_pre_prod_account[0].id
}

#manually added/managed value
data "aws_secretsmanager_secret" "subnet_value_for_qlik_sense_pre_prod_instance" {
  count = !var.is_production_environment && var.is_live_environment ? 1 : 0
  name  = "${var.identifier_prefix}-manually-managed-value-subnet-value-for-qlik-sense-restore-pre-prod-instance"
}

data "aws_secretsmanager_secret_version" "subnet_value_for_qlik_sense_pre_prod_instance" {
  count     = !var.is_production_environment && var.is_live_environment ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.subnet_value_for_qlik_sense_pre_prod_instance[0].id
}

resource "aws_instance" "qlik_sense_pre_prod_instance" {
  count                     = !var.is_production_environment && var.is_live_environment ? 1 : 0
  ami                       = local.backup_ami_id
  instance_type             = "c5.4xlarge"
  subnet_id                 = data.aws_secretsmanager_secret_version.subnet_value_for_qlik_sense_pre_prod_instance[0].secret_string
  #vpc_security_group_ids    = [aws_security_group.qlik_sense.id]
  
  private_dns_name_options {
    enable_resource_name_dns_a_record = true
  }

  iam_instance_profile        = aws_iam_instance_profile.qlik_sense.id
  disable_api_termination     = true
  key_name                    = aws_key_pair.qlik_sense_server_key.key_name
  tags                        = merge(var.tags, local.ec2_tags)
  associate_public_ip_address = false

  root_block_device {
    encrypted               = true
    delete_on_termination   = false
    kms_key_id              = data.aws_secretsmanager_secret_version.production_account_qlik_ec2_ebs_encryption_key_arn[0].secret_string
    tags                    = merge(var.tags, local.ec2_tags)
    volume_size             = 1000
    volume_type             = "gp3"
  }
  
  lifecycle {
    ignore_changes = [ami, subnet_id]
  }
}
