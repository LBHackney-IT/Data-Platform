locals {
  backup_ami_id = "ami-0b08cd4ad0a6162e3"
  ec2_tags = {
    BackupPolicy = title(var.environment)
    Name         = "${var.identifier_prefix}-qlik-sense-restore"
  }

  backup_ami_id_to_restore = "ami-0462df3547bccd38d"
  ec2_tags_for_restore = {
    BackupPolicy = title(var.environment)
    Name         = "${var.identifier_prefix}-qlik-sense-restore-2"
  }
}

resource "aws_ami_launch_permission" "ami_permissions_for_pre_prod" {
  count      = var.is_production_environment ? 1 : 0
  image_id   = local.backup_ami_id_to_restore
  account_id = data.aws_secretsmanager_secret_version.pre_production_account_id[0].secret_string
}

data "aws_secretsmanager_secret" "pre_production_account_id" {
  count = var.is_production_environment ? 1 : 0
  name  = "manual/pre-production-account-id"
}

data "aws_secretsmanager_secret_version" "pre_production_account_id" {
  count     = var.is_production_environment ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.pre_production_account_id[0].id
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
  count                  = !var.is_production_environment && var.is_live_environment ? 1 : 0
  ami                    = local.backup_ami_id
  instance_type          = "c5.4xlarge"
  subnet_id              = data.aws_secretsmanager_secret_version.subnet_value_for_qlik_sense_pre_prod_instance[0].secret_string
  vpc_security_group_ids = [aws_security_group.qlik_sense.id]

  private_dns_name_options {
    enable_resource_name_dns_a_record = true
  }

  iam_instance_profile        = aws_iam_instance_profile.qlik_sense.id
  disable_api_termination     = true
  key_name                    = aws_key_pair.qlik_sense_server_key.key_name
  tags                        = merge(var.tags, local.ec2_tags)
  associate_public_ip_address = false

  root_block_device {
    encrypted             = true
    delete_on_termination = false
    kms_key_id            = aws_kms_key.key.arn
    tags                  = merge(var.tags, local.ec2_tags)
    volume_size           = 1000
    volume_type           = "gp3"
  }

  lifecycle {
    ignore_changes = [ami, subnet_id]
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }
}

resource "aws_instance" "qlik_sense_pre_prod_instance_restore_2" {
  count                  = !var.is_production_environment && var.is_live_environment ? 1 : 0
  ami                    = local.backup_ami_id_to_restore
  instance_type          = "c5.4xlarge"
  subnet_id              = data.aws_secretsmanager_secret_version.subnet_value_for_qlik_sense_pre_prod_instance[0].secret_string
  vpc_security_group_ids = [aws_security_group.qlik_sense.id]

  private_dns_name_options {
    enable_resource_name_dns_a_record = true
  }

  iam_instance_profile        = aws_iam_instance_profile.qlik_sense.id
  disable_api_termination     = true
  key_name                    = aws_key_pair.qlik_sense_server_key.key_name
  tags                        = merge(var.tags, local.ec2_tags_for_restore)
  associate_public_ip_address = false

  root_block_device {
    encrypted             = true
    delete_on_termination = false
    kms_key_id            = aws_kms_key.key.arn
    tags                  = merge(var.tags, local.ec2_tags_for_restore)
    volume_size           = 1000
    volume_type           = "gp3"
  }

  lifecycle {
    ignore_changes = [ami, subnet_id]
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }
}
