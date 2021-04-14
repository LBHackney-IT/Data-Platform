# Core Infrastructure - qlikview APP

module "qlikview_app_security_group" {
  providers = { aws = aws.core }
  source    = "terraform-aws-modules/security-group/aws"
  version   = "~> 3.0"

  description         = format("Security group for %s.", var.application)
  egress_rules        = ["all-all"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp","all-icmp"]

  name   = format("%s-%s", var.application, var.environment)
  vpc_id = module.core_vpc.vpc_id

  tags = module.tags.values
}
