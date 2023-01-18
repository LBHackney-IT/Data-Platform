#temporary test instance to help troubleshoot issues with Qlik migration config
locals {
    win_prod_test_ec2_tags = {
        Name = "${var.identifier_prefix}-windows-test"
    }
}

#manually added/managed value
data "aws_secretsmanager_secret" "subnet_value_for_win_test_prod_instance" {
  count = var.is_production_environment ? 1 : 0
  name  = "${var.identifier_prefix}-manually-managed-value-subnet-value-for-prod-windows-test-instance"
}

data "aws_secretsmanager_secret_version" "subnet_value_for_win_test_prod_instance" {
  count     = var.is_production_environment ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.subnet_value_for_win_test_prod_instance[0].id
}

resource "aws_instance" "test_windows_prod_instance" {
  count                     = var.is_production_environment ? 1 : 0
  ami                       = "ami-0de6fdab89840d48f"
  instance_type             = "t2.micro"
  subnet_id                 = data.aws_secretsmanager_secret_version.subnet_value_for_win_test_prod_instance[0].secret_string
  vpc_security_group_ids    = [aws_security_group.qlik_sense.id]

  private_dns_name_options {
    enable_resource_name_dns_a_record = true
  }

  iam_instance_profile        = aws_iam_instance_profile.qlik_sense.id
  disable_api_termination     = false
  key_name                    = aws_key_pair.qlik_sense_server_key.key_name
  tags                        = merge(var.tags, local.win_prod_test_ec2_tags)
  associate_public_ip_address = false

  root_block_device {
    encrypted               = true
    delete_on_termination   = true
    kms_key_id              = aws_kms_key.key.arn
    tags                    = merge(var.tags, local.win_prod_test_ec2_tags)
  }
}
