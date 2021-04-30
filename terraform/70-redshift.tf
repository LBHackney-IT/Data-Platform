module "transit_gateway" {
  source               = "../modules/transit_gateway"
  core_azs             = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  core_cidr            = var.transit_gateway_cidr
  core_private_subnets = ["10.120.30.0/26", "10.120.30.64/26", "10.120.30.128/26"]
  application          = var.application
  department           = var.department
  environment          = var.environment
}
