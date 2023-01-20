locals {
    test_instance_backup_ami_id = "ami-0513e39717f73ef78"
    win_pre_prod_test_restore_ec2_tags = {
        Name = "${var.identifier_prefix}-manual-windows-test-restore-from-prod"
    }
}

#share the backup AMI from prod
resource "aws_ami_launch_permission" "ami_permissions_for_pre_prod_for_test_instance" {
  count         = var.is_production_environment ? 1 : 0
  image_id      = local.test_instance_backup_ami_id
  account_id    = data.aws_secretsmanager_secret_version.pre_production_account_id[0].secret_string
}

# resource "aws_instance" "test_windows_restore_from_prod_to_pre_prod" {
#   count                     = !var.is_production_environment && var.is_live_environment ? 1 : 0
#   ami                       = local.test_instance_backup_ami_id
#   instance_type             = "t2.micro"
#   subnet_id                 = data.aws_secretsmanager_secret_version.subnet_value_for_qlik_sense_pre_prod_instance[0].secret_string
#   vpc_security_group_ids    = [aws_security_group.qlik_sense.id]

#   private_dns_name_options {
#     enable_resource_name_dns_a_record = true
#   }

#   iam_instance_profile        = aws_iam_instance_profile.qlik_sense.id
#   disable_api_termination     = false
#   key_name                    = aws_key_pair.qlik_sense_server_key.key_name
#   tags                        = merge(var.tags, local.win_pre_prod_test_restore_ec2_tags)
#   associate_public_ip_address = false

#   root_block_device {
#     encrypted               = true
#     delete_on_termination   = true
#     kms_key_id              = aws_kms_key.key.arn
#     tags                    = merge(var.tags, local.win_pre_prod_test_restore_ec2_tags)
#   }
# }
