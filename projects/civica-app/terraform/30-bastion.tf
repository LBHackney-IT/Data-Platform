# Core Infrastructure - Bastion
module "bastion_ec2_instance" {
  providers = { aws = aws.core }
  source    = "terraform-aws-modules/ec2-instance/aws"
  version   = "2.16.0"

  ami                         = var.bastion_instance_ami
  associate_public_ip_address = true
  instance_count              = var.bastion_instance_number
  instance_type               = var.bastion_instance_type
  key_name                    = aws_key_pair.generated_key.key_name
  name                        = format("bastion-%s", var.environment)
  subnet_ids                  = module.core_vpc.public_subnets
  vpc_security_group_ids      = [module.bastion_security_group.this_security_group_id]

  tags = module.tags.values
}
