module "qlik_server" {
  count = local.is_live_environment ? 1 : 0

  source            = "../modules/qlik-sense-server"
  tags              = module.tags.values
  vpc_id            = data.aws_vpc.network.id
  vpc_subnet_ids    = local.subnet_ids_list
  instance_type     = var.qlik_server_instance_type
  identifier_prefix = local.identifier_prefix
}

module "qlik_sense_enterprise" {
  count = local.is_live_environment ? 1 : 0

  source            = "../modules/qlik-sense-enterprise"
  tags              = module.tags.values
  vpc_id            = data.aws_vpc.network.id
  vpc_subnet_ids    = local.subnet_ids_list
  instance_type     = var.qlik_server_instance_type
  identifier_prefix = local.identifier_prefix
}