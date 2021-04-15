# Core Infrastructure

# Core Infrastructure - Bastion
module "bastion_security_group" {
  providers = { aws = aws.core }
  source    = "terraform-aws-modules/security-group/aws"
  version   = "~> 3.0"

  description         = "Security group for Bastion."
  egress_rules        = ["all-all"]
  ingress_cidr_blocks = var.whitelist
  ingress_rules       = ["ssh-tcp", "all-icmp"]
  name                = format("bastion-%s", var.environment)
  vpc_id              = module.core_vpc.vpc_id

  tags = module.tags.values
}
