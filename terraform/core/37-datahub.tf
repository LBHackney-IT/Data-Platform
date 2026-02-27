module "datahub" {
  count = local.is_live_environment ? 1 : 0

  source                  = "../modules/datahub"
  tags                    = module.tags.values
  short_identifier_prefix = local.short_identifier_prefix
  identifier_prefix       = local.identifier_prefix
  vpc_id                  = data.aws_vpc.network.id
  vpc_subnet_ids          = local.subnet_ids_list
  is_live_environment     = local.is_live_environment
  datahub_url             = var.datahub_url
  kafka_properties = {
    kafka_zookeeper_connect = module.kafka_event_streaming[0].cluster_config.zookeeper_connect_string
    kafka_bootstrap_server  = module.kafka_event_streaming[0].cluster_config.bootstrap_brokers_tls
  }
  schema_registry_properties = {
    schema_registry_url = module.kafka_event_streaming[0].schema_registry_url
  }
}
