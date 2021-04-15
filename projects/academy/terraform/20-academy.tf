# Core Infrastructure

# Core Infrastructure - Academy
module "academy_ec2_instance" {
  providers = { aws = aws.core }
  source    = "terraform-aws-modules/ec2-instance/aws"
  version   = "2.16.0"

  ami = var.academy_instance_ami
  ebs_block_device = [
    {
      encrypted   = true
      device_name = "/dev/sdb"
      volume_size = "3000"
    },
    {
      encrypted   = true
      device_name = "/dev/sdc"
      volume_size = "500"
    },
  ]
  ebs_optimized        = true
  iam_instance_profile = aws_iam_instance_profile.academy_instance_profile.name
  instance_count       = var.academy_instance_number
  instance_type        = var.academy_instance_type
  key_name             = aws_key_pair.generated_key.key_name
  name                 = format("%s-%s", var.application, var.environment)
  root_block_device = [
    {
      encrypted   = true
      device_name = "/dev/sda"
      volume_size = "100"
    }
  ]
  subnet_ids             = module.core_vpc.private_subnets
  user_data              = var.academy_user_data
  vpc_security_group_ids = [module.academy_security_group.this_security_group_id]

  tags = module.tags.values
}
