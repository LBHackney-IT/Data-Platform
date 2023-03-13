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
  topics                                 = local.topics
  is_live_environment                    = var.is_live_environment

  datahub_gms_security_group_id           = var.datahub_gms_security_group_id
  datahub_mae_consumer_security_group_id  = var.datahub_mae_consumer_security_group_id
  datahub_mce_consumer_security_group_id  = var.datahub_mce_consumer_security_group_id
  kafka_security_group_id                 = aws_security_group.kafka.id
  housing_intra_account_ingress_cidr      = local.kafka_intra_account_ingress_rules["cidr_blocks"]
  schema_registry_alb_security_group_id   = module.schema_registry.load_balancer_security_group_id
  kafka_tester_lambda_security_group_id   = var.kafka_tester_lambda_security_group_id
}
