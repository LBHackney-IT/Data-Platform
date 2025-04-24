locals {
  backup_ami_id_prod = "ami-0a9bac68a32217ec9"
  ec2_tags_prod = {
    Application  = "Qlik"
    BackupPolicy = title(var.environment)
    Name         = "${var.identifier_prefix}-qlik-sense-restore"
  }
  ec2_tags_prod_restore = {
    Application  = "Qlik"
    BackupPolicy = title(var.environment)
    Name         = "${var.identifier_prefix}-qlik-sense-restore-2"
  }
}

#manually added/managed value
data "aws_secretsmanager_secret" "subnet_value_for_qlik_sense_prod_instance" {
  count = var.is_production_environment ? 1 : 0
  name  = "${var.identifier_prefix}-manually-managed-value-subnet-value-for-qlik-sense-restore-prod-instance"
}

data "aws_secretsmanager_secret_version" "subnet_value_for_qlik_sense_prod_instance" {
  count     = var.is_production_environment ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.subnet_value_for_qlik_sense_prod_instance[0].id
}

resource "aws_instance" "qlik_sense_prod_instance" {
  count                  = var.is_production_environment ? 1 : 0
  ami                    = local.backup_ami_id_prod
  instance_type          = "c6i.4xlarge"
  subnet_id              = data.aws_secretsmanager_secret_version.subnet_value_for_qlik_sense_prod_instance[0].secret_string
  vpc_security_group_ids = [aws_security_group.qlik_sense.id]

  private_dns_name_options {
    enable_resource_name_dns_a_record = true
  }

  iam_instance_profile        = aws_iam_instance_profile.qlik_sense.id
  disable_api_termination     = true
  key_name                    = aws_key_pair.qlik_sense_server_key.key_name
  tags                        = merge(var.tags, local.ec2_tags_prod)
  associate_public_ip_address = false

  root_block_device {
    encrypted             = true
    delete_on_termination = false
    kms_key_id            = aws_kms_key.key.arn
    # BackupPolicy tags will be automatically removed from volumes by cloud custodian
    # https://github.com/LBHackney-IT/ce-cloud-custodian/blob/be250a45b282b9bd3771cc0990a8a8e00c669888/custodian/policies/prod-ou/remove-tag-from-ebs-volumes.yaml
    tags = {
      for key, value in merge(var.tags, local.ec2_tags_prod) :
      key => value if key != "BackupPolicy"
    }
    volume_size = 1000
    volume_type = "gp3"
  }

  lifecycle {
    ignore_changes = [ami, subnet_id]
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }
}
