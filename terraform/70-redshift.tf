module "transit_gateway" {
  source               = "../modules/transit-gateway"
  core_azs             = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  core_cidr            = var.transit_gateway_cidr
  core_private_subnets = var.transit_gateway_private_subnets
  application          = var.application
  department           = var.department
  environment          = var.environment
}
