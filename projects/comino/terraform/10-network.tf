# Core Infrastructure
module "core_vpc" {
  providers = { aws = aws.core }
  source    = "terraform-aws-modules/vpc/aws"
  version   = "2.64.0"

  azs                            = var.core_azs
  cidr                           = var.core_cidr
  create_igw                     = var.core_create_igw
  default_security_group_egress  = var.core_security_group_egress
  default_security_group_ingress = var.core_security_group_ingress
  default_security_group_name    = format("%s-%s-core-vpc-sg", var.application, var.environment)
  enable_dns_hostnames           = var.core_enable_dns_hostnames
  enable_dns_support             = var.core_enable_dns_support
  enable_nat_gateway             = var.core_enable_nat_gateway
  manage_default_security_group  = true
  name                           = format("%s-%s", var.application, var.environment)
  private_subnets                = var.core_private_subnets
  public_subnets                 = var.core_public_subnets
  single_nat_gateway             = var.core_single_nat_gateway

  default_security_group_tags = module.tags.values
  tags                        = module.tags.values
}

