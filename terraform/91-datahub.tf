module "datahub" {
  source                  = "../modules/datahub"
  tags                    = module.tags.values
  environment             = var.environment
  identifier_prefix       = local.identifier_prefix
  short_identifier_prefix = local.short_identifier_prefix
  vpc_id                  = data.aws_vpc.network.id
  kafka_properties = {
    kafka_zookeeper_connect = module.kafka_event_streaming.cluster_config.zookeeper_connect_string
    kafka_bootstrap_server  = module.kafka_event_streaming.cluster_config.bootstrap_brokers_tls
  }
  schema_registry_properties = {
    schema_registry_url = module.kafka_event_streaming.schema_registry_url
  }
}