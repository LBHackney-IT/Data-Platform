module "datahub_actions" {
  source = "../aws-ecs-docker-service"

  tags                             = var.tags
  operation_name                   = var.short_identifier_prefix
  ecs_cluster_arn                  = aws_ecs_cluster.datahub.arn
  environment                      = var.environment
  identifier_prefix                = var.identifier_prefix
  short_identifier_prefix          = var.short_identifier_prefix
  alb_id                           = null
  alb_target_group_arn             = null
  alb_security_group_id            = null
  vpc_id                           = var.vpc_id
  cloudwatch_log_group_name        = aws_cloudwatch_log_group.datahub.name
  container_properties             = local.datahub_actions
  datahub_private_dns_namespace_id = aws_service_discovery_private_dns_namespace.datahub.id
}

module "datahub_frontend_react" {
  source = "../aws-ecs-docker-service"

  tags                             = var.tags
  operation_name                   = var.short_identifier_prefix
  ecs_cluster_arn                  = aws_ecs_cluster.datahub.arn
  environment                      = var.environment
  identifier_prefix                = var.identifier_prefix
  short_identifier_prefix          = var.short_identifier_prefix
  alb_id                           = aws_alb.datahub.id
  alb_target_group_arn             = aws_alb_target_group.datahub.arn
  alb_security_group_id            = aws_security_group.datahub.id
  vpc_id                           = var.vpc_id
  cloudwatch_log_group_name        = aws_cloudwatch_log_group.datahub.name
  container_properties             = local.datahub_frontend_react
  datahub_private_dns_namespace_id = aws_service_discovery_private_dns_namespace.datahub.id
}

module "datahub_gms" {
  source = "../aws-ecs-docker-service"

  tags                             = var.tags
  operation_name                   = var.short_identifier_prefix
  ecs_cluster_arn                  = aws_ecs_cluster.datahub.arn
  environment                      = var.environment
  identifier_prefix                = var.identifier_prefix
  short_identifier_prefix          = var.short_identifier_prefix
  alb_id                           = null
  alb_target_group_arn             = null
  alb_security_group_id            = null
  vpc_id                           = var.vpc_id
  cloudwatch_log_group_name        = aws_cloudwatch_log_group.datahub.name
  container_properties             = local.datahub_gms
  datahub_private_dns_namespace_id = aws_service_discovery_private_dns_namespace.datahub.id
}

module "mysql_setup" {
  source = "../aws-ecs-docker-service"

  tags                             = var.tags
  operation_name                   = var.short_identifier_prefix
  ecs_cluster_arn                  = aws_ecs_cluster.datahub.arn
  environment                      = var.environment
  identifier_prefix                = var.identifier_prefix
  short_identifier_prefix          = var.short_identifier_prefix
  alb_id                           = null
  alb_target_group_arn             = null
  alb_security_group_id            = null
  vpc_id                           = var.vpc_id
  cloudwatch_log_group_name        = aws_cloudwatch_log_group.datahub.name
  container_properties             = local.mysql_setup
  datahub_private_dns_namespace_id = aws_service_discovery_private_dns_namespace.datahub.id
}

module "elasticsearch_setup" {
  source = "../aws-ecs-docker-service"

  tags                             = var.tags
  operation_name                   = var.short_identifier_prefix
  ecs_cluster_arn                  = aws_ecs_cluster.datahub.arn
  environment                      = var.environment
  identifier_prefix                = var.identifier_prefix
  short_identifier_prefix          = var.short_identifier_prefix
  alb_id                           = null
  alb_target_group_arn             = null
  alb_security_group_id            = null
  vpc_id                           = var.vpc_id
  cloudwatch_log_group_name        = aws_cloudwatch_log_group.datahub.name
  container_properties             = local.elasticsearch_setup
  datahub_private_dns_namespace_id = aws_service_discovery_private_dns_namespace.datahub.id
}

module "kafka_setup" {
  source = "../aws-ecs-docker-service"

  tags                             = var.tags
  operation_name                   = var.short_identifier_prefix
  ecs_cluster_arn                  = aws_ecs_cluster.datahub.arn
  environment                      = var.environment
  identifier_prefix                = var.identifier_prefix
  short_identifier_prefix          = var.short_identifier_prefix
  alb_id                           = null
  alb_target_group_arn             = null
  alb_security_group_id            = null
  vpc_id                           = var.vpc_id
  cloudwatch_log_group_name        = aws_cloudwatch_log_group.datahub.name
  container_properties             = local.kafka_setup
  datahub_private_dns_namespace_id = aws_service_discovery_private_dns_namespace.datahub.id
}

module "neo4j" {
  source = "../aws-ecs-docker-service"

  tags                             = var.tags
  operation_name                   = var.short_identifier_prefix
  ecs_cluster_arn                  = aws_ecs_cluster.datahub.arn
  environment                      = var.environment
  identifier_prefix                = var.identifier_prefix
  short_identifier_prefix          = var.short_identifier_prefix
  alb_id                           = null
  alb_target_group_arn             = null
  alb_security_group_id            = null
  vpc_id                           = var.vpc_id
  cloudwatch_log_group_name        = aws_cloudwatch_log_group.datahub.name
  container_properties             = local.neo4j
  datahub_private_dns_namespace_id = aws_service_discovery_private_dns_namespace.datahub.id
}
