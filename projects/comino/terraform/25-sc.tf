# Core Infrastructure - Social Care APP
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#ebs-ephemeral-and-root-block-devices
module "sc_app_ec2_instance" {
  providers = { aws = aws.core }
  source    = "terraform-aws-modules/ec2-instance/aws"
  version   = "2.16.0"

  ami = var.sc_app_instance_ami
  ebs_block_device = [
    {
      encrypted   = true
      device_name = "/dev/sdb"
      volume_size = "32"
    },
    {
      encrypted   = true
      device_name = "/dev/sdc"
      volume_size = "64"
    },
    {
      encrypted   = true
      device_name = "/dev/sdd"
      volume_size = "64"
    },
    {
      encrypted   = true
      device_name = "/dev/sdf"
      volume_size = "128"
    }
  ]
  ebs_optimized  = true
  instance_count = var.sc_app_instance_number
  instance_type  = var.sc_app_instance_type
  key_name       = var.key_name
  #name           = format("%s-%s", var.application, var.environment)
  name = format("comino-sc-%s", var.environment)
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
