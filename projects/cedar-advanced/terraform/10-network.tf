# AppStream Infrastructure
module "appstream_vpc" {
  providers = { aws = aws.appstream }
  source    = "terraform-aws-modules/vpc/aws"
  version   = "2.64.0"

  azs                            = var.appstream_azs
  cidr                           = var.appstream_cidr
  create_igw                     = var.appstream_create_igw
  default_security_group_egress  = var.appstream_security_group_egress
  default_security_group_ingress = var.appstream_security_group_ingress
  default_security_group_name    = format("%s-%s-appstream-vpc-sg", var.application, var.environment)
  enable_dns_hostnames           = var.appstream_enable_dns_hostnames
  enable_dns_support             = var.appstream_enable_dns_support
  enable_nat_gateway             = var.appstream_enable_nat_gateway
  manage_default_security_group  = true
  name                           = format("%s-%s", var.application, var.environment)
  private_subnets                = var.appstream_private_subnets
  public_subnets                 = var.appstream_public_subnets
  single_nat_gateway             = var.appstream_single_nat_gateway

  default_security_group_tags = module.tags.values
  tags                        = module.tags.values
}
