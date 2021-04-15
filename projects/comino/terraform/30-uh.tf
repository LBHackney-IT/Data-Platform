# Core Infrastructure - UNIVERSAL HOUSING APP
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#ebs-ephemeral-and-root-block-devices
module "uh_app_ec2_instance" {
  providers = { aws = aws.core }
  source    = "terraform-aws-modules/ec2-instance/aws"
  version   = "2.16.0"

  ami = var.uh_app_instance_ami
  ebs_block_device = [
    {
      encrypted   = true
      device_name = "/dev/sdb"
      volume_size = "32"
    }
  ]

  ebs_optimized  = true
  instance_count = var.uh_app_instance_number
  instance_type  = var.uh_app_instance_type
  key_name       = var.key_name
  #name           = format("%s-%s", var.application, var.environment)
  name = format("comino-uh-%s", var.environment)
  root_block_device = [
    {
      encrypted   = true
      device_name = "/dev/sda"
      volume_size = "128"
    }
  ]
  subnet_ids             = module.core_vpc.private_subnets
  vpc_security_group_ids = [module.comino_app_security_group.this_security_group_id]

  tags = module.tags.values
}
