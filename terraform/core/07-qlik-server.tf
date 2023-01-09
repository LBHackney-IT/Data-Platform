module "qlik_server" {
  count = local.is_live_environment ? 1 : 0

  source                    = "../modules/qlik-sense-server"
  tags                      = module.tags.values
  vpc_id                    = data.aws_vpc.network.id
  vpc_subnet_ids            = local.subnet_ids_list
  instance_type             = var.qlik_server_instance_type
  ssl_certificate_domain    = var.qlik_ssl_certificate_domain
  identifier_prefix         = local.identifier_prefix
  short_identifier_prefix   = local.short_identifier_prefix
  environment               = var.environment
  is_production_environment = local.is_production_environment
}
