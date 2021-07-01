module "qlik_server" {
  count = 1
  source = "../modules/qlik-sense-server"

  tags = module.tags.values
  vpc_id = data.aws_vpc.network.id
  vpc_subnet_ids = local.subnet_ids_list
  instance_type = var.qlik_server_instance_type
  identifier_prefix = local.identifier_prefix
}