# Core Infrastructure

# Core Infrastructure - Civica APP
module "civica_app_ec2_instance" {
  providers = { aws = aws.core }
  source    = "terraform-aws-modules/ec2-instance/aws"
  version   = "2.16.0"

  ami = var.civica_app_instance_ami
  ebs_block_device = [
    {
      encrypted   = true
      device_name = "/dev/sdb"
      volume_size = "3000"
    }
  ]
  ebs_optimized  = true
  instance_count = var.civica_app_instance_number
  instance_type  = var.civica_app_instance_type
  key_name       = var.key_name
  name           = format("%s-%s", var.application, var.environment)
  root_block_device = [
    {
      encrypted   = true
      device_name = "/dev/sda"
      volume_size = "100"
    }
  ]
  subnet_ids             = module.core_vpc.private_subnets
  vpc_security_group_ids = [module.civica_app_security_group.this_security_group_id]

  tags = module.tags.values
}

# module "civica_app_db_ec2_instance" {
#   providers = { aws = aws.core }
#   source    = "terraform-aws-modules/ec2-instance/aws"
#   version   = "2.16.0"

#   ami = var.civica_app_db_instance_ami
#   ebs_block_device = [
#     {
#       encrypted   = true
#       device_name = "/dev/sdb"
#       volume_size = "500"
#     },
#     {
#       encrypted   = true
#       device_name = "/dev/sdc"
#       volume_size = "500"
#     },
#     {
#       encrypted   = true
#       device_name = "/dev/sdd"
#       volume_size = "500"
#     }
#   ]
#   ebs_optimized  = true
#   instance_count = var.civica_app_db_instance_number
#   instance_type  = var.civica_app_db_instance_type
#   key_name       = var.key_name
#   name           = format("%s-db-%s", var.application, var.environment)
#   root_block_device = [
#     {
#       encrypted   = true
#       device_name = "/dev/sda"
#       volume_size = "100"
#     }
#   ]
#   subnet_ids             = module.core_vpc.private_subnets
#   vpc_security_group_ids = [module.civica_app_security_group.this_security_group_id]

#   tags = module.tags.values
# }
