module "kafka_test_lambda" {
  count                          = var.is_production_environment ? 0 : 1
  source                         = "../kafka-test-lambda"
  lambda_name                    = "kafka-test"
  tags                           = var.tags
  vpc_id                         = var.vpc_id
  subnet_ids                     = var.subnet_ids
  identifier_prefix              = var.short_identifier_prefix
  lambda_artefact_storage_bucket = var.lambda_artefact_storage_bucket
  kafka_cluster_arn              = aws_msk_cluster.kafka_cluster.arn
  kafka_cluster_kms_key_arn      = aws_kms_key.kafka.arn
  kafka_cluster_name             = aws_msk_cluster.kafka_cluster.cluster_name
  kafka_security_group_id        = aws_security_group.kafka.id
  lambda_environment_variables = {
    "TARGET_KAFKA_BROKERS" = aws_msk_cluster.kafka_cluster.bootstrap_brokers_tls
    "SCHEMA_REGISTRY_URL"  = "http://${module.schema_registry.load_balancer_dns_name}:8081"
  }
}