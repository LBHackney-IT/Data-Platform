locals {
  kafka_event_streaming_count = local.is_live_environment ? 1 : 0
  deploy_kafka_test_lambda    = local.kafka_event_streaming_count > 0 && !local.is_production_environment
}

module "kafka_event_streaming" {
  count       = local.kafka_event_streaming_count
  source      = "../modules/kafka-event-streaming"
  tags        = module.tags.values
  environment = var.environment
  project     = var.project

  glue_iam_role                          = aws_iam_role.glue_role.name
  glue_database_name                     = aws_glue_catalog_database.landing_zone_catalog_database.name
  is_live_environment                    = local.is_live_environment
  identifier_prefix                      = local.identifier_prefix
  short_identifier_prefix                = local.short_identifier_prefix
  vpc_id                                 = data.aws_vpc.network.id
  subnet_ids                             = data.aws_subnet_ids.network.ids
  s3_bucket_to_write_to                  = module.raw_zone
  bastion_private_key_ssm_parameter_name = aws_ssm_parameter.bastion_key.name
  bastion_instance_id                    = aws_instance.bastion.id
  role_arns_to_share_access_with         = ""
  cross_account_lambda_roles = [
    "arn:aws:iam::937934410339:role/mtfh-reporting-data-listener/development/mtfh-reporting-data-listener-lambdaExecutionRole",
    "arn:aws:iam::364864573329:role/mtfh-reporting-data-listener/development/mtfh-reporting-data-listener-lambdaExecutionRole"
  ]

  datahub_actions_security_group_id       = module.datahub[0].datahub_actions_security_group_id
  datahub_gms_security_group_id           = module.datahub[0].datahub_gms_service_security_group_id
  datahub_mae_consumer_security_group_id  = module.datahub[0].datahub_mae_security_group_id
  datahub_mce_consumer_security_group_id  = module.datahub[0].datahub_mce_security_group_id
  kafka_tester_lambda_security_group_id   = lower(var.environment) != "prod" ? module.kafka_test_lambda[0].security_group_id : ""
}

module "kafka_test_lambda" {
  count                          = local.deploy_kafka_test_lambda ? 1 : 0
  source                         = "../modules/kafka-test-lambda"
  lambda_name                    = "kafka-test"
  tags                           = module.tags.values
  vpc_id                         = data.aws_vpc.network.id
  subnet_ids                     = data.aws_subnet_ids.network.ids
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
  kafka_cluster_arn              = module.kafka_event_streaming[0].cluster_config.cluster_arn
  kafka_cluster_kms_key_arn      = module.kafka_event_streaming[0].cluster_config.kms_key_arn
  kafka_cluster_name             = module.kafka_event_streaming[0].cluster_config.cluster_name
  kafka_security_group_id        = module.kafka_event_streaming[0].cluster_config.vpc_security_groups
  lambda_environment_variables = {
    "TARGET_KAFKA_BROKERS" = module.kafka_event_streaming[0].cluster_config.bootstrap_brokers_tls
    "SCHEMA_REGISTRY_URL"  = module.kafka_event_streaming[0].schema_registry_url
  }
}