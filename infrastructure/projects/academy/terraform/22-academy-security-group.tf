# Core Infrastructure

# Core Infrastructure - Academy
module "academy_security_group" {
  providers = { aws = aws.core }
  source    = "terraform-aws-modules/security-group/aws"
  version   = "~> 3.0"

  description         = format("Security group for %s.", var.application)
  egress_rules        = ["all-all"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 26816
      to_port     = 26823
      protocol    = "tcp"
      description = "Ingres 10.2 listen address of TX."
      cidr_blocks = join(",", var.appstream_private_subnets)
    },
    {
      from_port   = var.environment == "prod" ? 21000 : 22000
      to_port     = var.environment == "prod" ? 21010 : 22010
      protocol    = "tcp"
      description = "NDR calculation ports."
      cidr_blocks = join(",", var.appstream_private_subnets)
    }
  ]
  ingress_with_source_security_group_id = [
    {
      rule                     = "ssh-tcp"
      source_security_group_id = module.bastion_security_group.this_security_group_id
    }
  ]
  name   = format("%s-%s", var.application, var.environment)
  vpc_id = module.core_vpc.vpc_id

  tags = module.tags.values
}
