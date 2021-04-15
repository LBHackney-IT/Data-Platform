# Core Infrastructure - SQL Database Server serving all 3 Apps

module "db_ec2_instance" {
  providers = { aws = aws.core }
  source    = "terraform-aws-modules/ec2-instance/aws"
  version   = "2.16.0"

  ami = var.db_instance_ami
  ebs_block_device = [
    {
      encrypted   = true
      device_name = "/dev/sdb"
      volume_size = "32"
    },
    {
      encrypted   = true
      device_name = "/dev/sdc"
      volume_size = "32"
    },
    {
      encrypted   = true
      device_name = "/dev/sdd"
      volume_size = "512"
    },
    {
      encrypted   = true
      device_name = "/dev/sdf"
      volume_size = "256"
    }
  ]
  ebs_optimized  = true
  instance_count = var.db_instance_number
  instance_type  = var.db_instance_type
  key_name       = var.key_name
  #name           = format("%s-%s", var.application, var.environment)
  name = format("comino-database-%s", var.environment)
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
