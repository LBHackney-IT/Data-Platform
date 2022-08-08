module "schema_registry" {
  source                                 = "../kafka-schema-registry"
  tags                                   = var.tags
  environment                            = var.environment
  identifier_prefix                      = var.short_identifier_prefix
  project                                = var.project
  vpc_id                                 = var.vpc_id
  subnet_ids                             = var.subnet_ids
  bootstrap_servers                      = aws_msk_cluster.kafka_cluster.bootstrap_brokers_tls
  bastion_private_key_ssm_parameter_name = var.bastion_private_key_ssm_parameter_name
  bastion_instance_id                    = var.bastion_instance_id
  topics                                 = var.topics
  is_live_environment                    = var.is_live_environment
}