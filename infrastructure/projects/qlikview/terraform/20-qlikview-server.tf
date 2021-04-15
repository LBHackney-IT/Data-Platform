# Core Infrastructure - qlikview APP
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#ebs-ephemeral-and-root-block-devices
module "qlikview_app_ec2_instance" {
  providers = { aws = aws.core }
  source    = "terraform-aws-modules/ec2-instance/aws"
  version   = "2.16.0"

  ami = var.qlikview_app_instance_ami
  ebs_block_device = [
    {
      encrypted   = true
      device_name = "/dev/sdb"
      volume_size = "128"
    },
    {
      encrypted   = true
      device_name = "/dev/sdc"
      volume_size = "128"
    }
  ]
  ebs_optimized  = true
  iam_instance_profile = aws_iam_instance_profile.qlikview_app_instance_profile.name
  instance_count = var.qlikview_app_instance_number
  instance_type  = var.qlikview_app_instance_type
  key_name       = aws_key_pair.generated_key.key_name
  name           = format("%s-%s", var.application, var.environment)
  root_block_device = [
    {
      encrypted   = true
      device_name = "/dev/sda"
      volume_size = "128"
    }
  ]
  subnet_ids             = module.core_vpc.private_subnets
  vpc_security_group_ids = [module.qlikview_app_security_group.this_security_group_id]

  tags = module.tags.values
}
