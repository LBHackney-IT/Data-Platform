module "datahub" {
  source                  = "../modules/datahub"
  tags                    = module.tags.values
  operation_name          = local.short_identifier_prefix
  environment             = var.environment
  identifier_prefix       = local.identifier_prefix
  short_identifier_prefix = local.short_identifier_prefix
  vpc_id                  = data.aws_vpc.network.id
  rds_properties = {
    host     = ""
    port     = 1
    username = ""
    password = ""
    db_name  = ""
  }
  elasticsearch_properties = {
    host     = ""
    port     = 1
    protocol = "http"
  }
  kafka_properties = {
    kafka_zookeeper_connect = module.kafka_event_streaming.cluster_config.zookeeper_connect_string
    kafka_bootstrap_server  = module.kafka_event_streaming.cluster_config.bootstrap_brokers_tls
  }
  schema_registry_properties = {
    host_name                 = ""
    kafkastore_connection_url = ""
  }
}